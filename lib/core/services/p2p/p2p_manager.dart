import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:verifier_facl/core/models/attendance_record.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';

import 'package:verifier_facl/core/services/crypto_service.dart';
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

  Future<void> startSession(String classId, String facultyName) async {
    try {
      if (!await _nearbyService.checkPermissions()) {
        throw Exception("Required P2P permissions were not granted.");
      }

      _currentClassId = classId;
      _currentSessionId =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';

      await _nearbyService.startAdvertising(facultyName);

      _payloadSubscription =
          _nearbyService.payloadStream.listen(_handleStudentPayload);

      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.sessionStarted,
        message: 'Session started successfully.',
      ));
    } catch (e) {
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.error,
        message: 'Failed to start session: $e',
      ));
      await stopSession();
      rethrow;
    }
  }

  Future<void> _handleStudentPayload(ReceivedPayload payload) async {
    final data = jsonDecode(payload.data);
    final messageType = data['type'];

    switch (messageType) {
      case 'attendance_request':
        final studentId = data['studentId'] as String;
        final challenge = _cryptoService.generateChallenge();
        _pendingChallenges[studentId] = challenge;

        await _sendPayload(
          payload.endpointId,
          'challenge',
          {
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
        break;

      case 'challenge_response':
        final studentId = data['studentId'] as String;
        final signature = data['signature'] as String;
        final challenge = _pendingChallenges.remove(studentId);

        if (challenge == null) {
          await _sendPayload(payload.endpointId, 'attendance_result',
              {'success': false, 'message': 'Challenge expired or invalid.'});
          return;
        }

        final student = await _ref
            .read(databaseProvider)
            .studentDao
            .findStudentByStudentIdAndClassId(studentId, _currentClassId!);

        if (student == null) {
          await _sendPayload(payload.endpointId, 'attendance_result',
              {'success': false, 'message': 'Student not found in this class.'});
          return;
        }

        final isValid = _cryptoService.verifySignature(
           challenge,
           signature,
          student.publicKey,
        );

        if (isValid) {
          await _markAttendance(student, 'present');
          await _sendPayload(payload.endpointId, 'attendance_result',
              {'success': true, 'message': 'Attendance marked successfully.'});
          _attendanceUpdateController.add(AttendanceUpdate(
            type: AttendanceUpdateType.studentVerified,
            studentId: studentId,
            studentName: student.name,
            message: '${student.name} marked present.',
          ));
        } else {
          await _sendPayload(payload.endpointId, 'attendance_result', {
            'success': false,
            'message': 'Invalid signature. Verification failed.'
          });
          _attendanceUpdateController.add(AttendanceUpdate(
            type: AttendanceUpdateType.studentFailed,
            studentId: studentId,
            studentName: student.name,
            message: 'Verification failed for ${student.name}.',
          ));
        }
        break;
    }
  }

  Future<void> _sendPayload(
      String endpointId, String type, Map<String, dynamic> data) async {
    final payload = {'type': type, ...data};
    await _nearbyService.sendPayload(endpointId, payload);
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
      createdAt: DateTime.now(),
      verifiedAt: status == 'present' ? DateTime.now() : null,
    );
    await db.attendanceRecordDao.insertAttendanceRecord(record);
  }

  Future<void> stopSession() async {
    if (_currentSessionId == null || _currentClassId == null) return;
    final db = _ref.read(databaseProvider);

    await _nearbyService.stopAdvertising();
    await _nearbyService.disconnectFromAll();

    final presentRecords = await db.attendanceRecordDao
        .findPresentRecordsBySessionId(_currentSessionId!);
    final presentStudentIds = presentRecords.map((r) => r.studentId).toSet();

    final allStudents =
        await db.studentDao.findStudentsByClassId(_currentClassId!);
    final absentStudents = allStudents
        .where((student) => !presentStudentIds.contains(student.studentId));

    for (final student in absentStudents) {
      await _markAttendance(student, 'absent');
    }

    _attendanceUpdateController.add(AttendanceUpdate(
      type: AttendanceUpdateType.sessionEnded,
      message: 'Session has ended. Absent students marked.',
    ));

    _pendingChallenges.clear();
    await _payloadSubscription?.cancel();
    _currentSessionId = null;
    _currentClassId = null;
  }

  void dispose() {
    stopSession();
    _attendanceUpdateController.close();
  }
}
