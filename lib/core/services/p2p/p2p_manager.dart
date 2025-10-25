import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:verifier_facl/core/models/attendance_record.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/services/crypto/crypto_service.dart';
import 'package:verifier_facl/core/services/p2p/nearby_connections_service.dart';
import 'package:verifier_facl/core/utils/constants.dart';

enum AttendanceUpdateType {
  sessionStarted,
  studentConnected,
  studentVerified,
  studentFailed,
  sessionEnded,
  error,
}

class AttendanceUpdate {
  final AttendanceUpdateType type;
  final String message;
  final String? studentId;
  final String? studentName;

  AttendanceUpdate({
    required this.type,
    required this.message,
    this.studentId,
    this.studentName,
  });
}

class P2PManager {
  final Ref _ref;
  final NearbyConnectionsService _nearbyService;
  final CryptoService _cryptoService;

  P2PManager(this._ref, this._nearbyService, this._cryptoService);

  final Map<String, String> _pendingChallenges = {};
  StreamSubscription? _payloadSubscription;
  String? _currentSessionId;
  String? _currentClassId;

  final _attendanceUpdateController =
      StreamController<AttendanceUpdate>.broadcast();
  Stream<AttendanceUpdate> get attendanceStream =>
      _attendanceUpdateController.stream;

  String? get currentSessionId => _currentSessionId;

  Future<String> startSession(String classId) async {
    try {
      final faculty = _ref.read(currentFacultyProvider);
      if (faculty == null) {
        throw Exception('Faculty not logged in.');
      }

      _currentSessionId =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';
      _currentClassId = classId;

      await _nearbyService.startAdvertising(faculty.username);

      _payloadSubscription =
          _nearbyService.payloadStream.listen(_handleStudentPayload);
      
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.sessionStarted,
        message: 'Session started. Waiting for students...',
      ));

      return _currentSessionId!;
    } catch (e) {
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.error,
        message: 'Failed to start session: $e',
      ));
      await stopSession();
      rethrow;
    }
  }

  void _handleStudentPayload(ReceivedPayload payload) {
      final messageString = payload.data;
      final data = jsonDecode(messageString);
      final messageType = data['type'] as String?;

      switch (messageType) {
        case 'attendance_request':
          _handleAttendanceRequest(data, payload.endpointId);
          break;
        case 'challenge_response':
          _handleChallengeResponse(data, payload.endpointId);
          break;
      }
  }
  
  Future<void> _handleAttendanceRequest(Map<String, dynamic> data, String endpointId) async {
    final studentId = data['studentId'] as String;
    final challenge = _cryptoService.generateChallenge();
    _pendingChallenges[studentId] = challenge;

    await _nearbyService.sendPayload(
      endpointId,
      {
        'type': 'challenge',
        'challenge': challenge,
        'sessionId': _currentSessionId,
      },
    );

    Timer(AppConstants.challengeTimeout, () {
      if (_pendingChallenges.containsKey(studentId)) {
        _pendingChallenges.remove(studentId);
        print('Challenge for $studentId expired.');
      }
    });
  }

  Future<void> _handleChallengeResponse(Map<String, dynamic> data, String endpointId) async {
    final studentId = data['studentId'] as String;
    final signature = data['signature'] as String;
    final challenge = _pendingChallenges.remove(studentId);

    if (challenge == null) {
      await _sendResult(endpointId, false, 'Challenge expired or invalid.');
      return;
    }

    final student = await _ref
        .read(databaseProvider)
        .studentDao
        .findStudentByStudentIdAndClassId(studentId, _currentClassId!);
    
    if (student == null) {
      await _sendResult(endpointId, false, 'Student not found in this class.');
      return;
    }

    final isValid = _cryptoService.verifySignature(
      message: challenge,
      signature: signature,
      publicKeyPem: student.publicKey,
    );

    if (isValid) {
      await _markAttendance(student, 'present');
      await _sendResult(endpointId, true, 'Attendance marked successfully.');
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.studentVerified,
        studentId: studentId,
        studentName: student.name,
        message: '${student.name} marked present.',
      ));
    } else {
      await _sendResult(endpointId, false, 'Invalid signature. Verification failed.');
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.studentFailed,
        studentId: studentId,
        studentName: student.name,
        message: 'Verification failed for ${student.name}.',
      ));
    }
  }

  Future<void> _sendResult(String endpointId, bool success, String message) async {
    await _nearbyService.sendPayload(
        endpointId,
        {
          'type': 'attendance_result',
          'success': success,
          'message': message,
        });
  }

  Future<void> _markAttendance(Student student, String status) async {
    final db = _ref.read(databaseProvider);
    final record = AttendanceRecord(
      recordId: const Uuid().v4(),
      classId: _currentClassId!,
      studentId: student.studentId,
      sessionId: _currentSessionId!,
      date: DateTime.now(),
      status: status,
      verifiedAt: status == 'present' ? DateTime.now() : null,
      createdAt: DateTime.now(),
    );
    await db.attendanceRecordDao.insertAttendanceRecord(record);
  }

  Future<void> stopSession() async {
    if (_currentSessionId == null) return;
    
    await _nearbyService.disconnectFromAll();

    if (_currentClassId != null) {
      final db = _ref.read(databaseProvider);
      final presentRecords = await db.attendanceRecordDao.findPresentRecordsBySessionId(_currentSessionId!);
      final presentStudentIds = presentRecords.map((r) => r.studentId).toSet();
      final allStudents = await db.studentDao.findStudentsByClassId(_currentClassId!);
      final absentStudents = allStudents.where((s) => !presentStudentIds.contains(s.studentId));

      for (final student in absentStudents) {
        await _markAttendance(student, 'absent');
      }
    }
    
    _attendanceUpdateController.add(AttendanceUpdate(
      type: AttendanceUpdateType.sessionEnded,
      message: 'Session has ended.',
    ));

    _pendingChallenges.clear();
    _payloadSubscription?.cancel();
    _currentSessionId = null;
    _currentClassId = null;
  }

  void dispose() {
    stopSession();
    _attendanceUpdateController.close();
  }
}
