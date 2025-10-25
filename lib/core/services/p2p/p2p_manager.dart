import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:verifier_facl/core/models/attendance_record.dart'; // Ensure correct import path
import 'package:verifier_facl/core/models/student.dart';          // Ensure correct import path
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/services/crypto/crypto_service.dart'; // Ensure correct import path
import 'package:verifier_facl/core/services/p2p/nearby_connections_service.dart'; // Ensure correct import path
import 'package:verifier_facl/core/utils/constants.dart';             // Ensure correct import path
import 'package:nearby_connections/nearby_connections.dart';              // Import from plugin

enum AttendanceUpdateType {
  sessionStarted,
  studentConnected, // May not be directly applicable with Nearby Connections advertising
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

  // Optional: Override == and hashCode for better list management if needed
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceUpdate &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          studentId == other.studentId;

  @override
  int get hashCode => type.hashCode ^ message.hashCode ^ studentId.hashCode;
}

class P2PManager {
  final Ref _ref;
  final NearbyConnectionsService _nearbyService;
  final CryptoService _cryptoService;

  P2PManager(this._ref, this._nearbyService, this._cryptoService);

  final Map<String, String> _pendingChallenges = {}; // Map<studentId, challenge>
  StreamSubscription? _payloadSubscription;
  String? _currentSessionId;
  String? _currentClassId;

  final _attendanceUpdateController =
      StreamController<AttendanceUpdate>.broadcast();
  Stream<AttendanceUpdate> get attendanceStream =>
      _attendanceUpdateController.stream;

  String? get currentSessionId => _currentSessionId;

  // --- Start Session ---
  Future<String> startSession(String classId) async {
    try {
      final faculty = _ref.read(currentFacultyProvider);
      if (faculty == null) {
        throw Exception('Faculty not logged in.');
      }
      print("[Faculty P2PManager] Starting session for class: $classId by ${faculty.username}");

      _currentSessionId =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';
      _currentClassId = classId;

      // Check permissions before starting advertising
      bool permissionsGranted = await _nearbyService.checkPermissions();
      if (!permissionsGranted) {
          throw Exception('Required permissions (Location, Bluetooth, Nearby Devices) not granted.');
      }

      await _nearbyService.startAdvertising(faculty.username);
      print("[Faculty P2PManager] Advertising started...");

      // Clear previous subscription if any
      _payloadSubscription?.cancel();
      _payloadSubscription =
          _nearbyService.payloadStream.listen(_handleStudentPayload);
      print("[Faculty P2PManager] Listening for student payloads...");

      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.sessionStarted,
        message: 'Session started. Waiting for students to connect...',
      ));

      return _currentSessionId!;
    } catch (e) {
      print("[Faculty P2PManager] Error starting session: $e");
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.error,
        message: 'Failed to start session: $e',
      ));
      await stopSession(); // Ensure cleanup on error
      rethrow;
    }
  }
  // --- End Start Session ---


  // --- Payload Handling ---
  void _handleStudentPayload(ReceivedPayload payload) {
     print("[Faculty P2PManager] Received payload from ${payload.endpointId}");
    if (payload.payload.type == PayloadType.BYTES && payload.payload.bytes != null) {
      try {
          final messageString = utf8.decode(payload.payload.bytes!);
          print("[Faculty P2PManager] Decoded payload: $messageString");
          final data = jsonDecode(messageString);
          final messageType = data['type'] as String?;

          switch (messageType) {
            case 'attendance_request':
              print("[Faculty P2PManager] Handling attendance_request from ${payload.endpointId}");
              _handleAttendanceRequest(data, payload.endpointId);
              break;
            case 'challenge_response':
              print("[Faculty P2PManager] Handling challenge_response from ${payload.endpointId}");
              _handleChallengeResponse(data, payload.endpointId);
              break;
            default:
              print("[Faculty P2PManager] Received unknown payload type: $messageType from ${payload.endpointId}");
          }
      } catch(e) {
         print("[Faculty P2PManager] Error decoding/processing payload from ${payload.endpointId}: $e");
         _sendResult(payload.endpointId, false, "Invalid message format.");
      }
    } else {
       print("[Faculty P2PManager] Received non-byte payload type: ${payload.payload.type} from ${payload.endpointId}");
    }
  }

  Future<void> _handleAttendanceRequest(Map<String, dynamic> data, String endpointId) async {
    final studentId = data['studentId'] as String?;
    if (studentId == null || _currentClassId == null) {
        print("[Faculty P2PManager] Invalid attendance request: missing studentId or classId not set.");
         _sendResult(endpointId, false, "Invalid request.");
        return;
    }

    // Check if student is enrolled in this class
    final student = await _ref.read(databaseProvider).studentDao.findStudentByStudentIdAndClassId(studentId, _currentClassId!);
    if (student == null) {
         print("[Faculty P2PManager] Student $studentId not found in class $_currentClassId. Rejecting request from $endpointId.");
        _sendResult(endpointId, false, "Student not enrolled in this class.");
        // Consider disconnecting if student is unknown?
        // _nearbyService.disconnectFromEndpoint(endpointId);
        return;
    }

    final challenge = _cryptoService.generateChallenge();
    _pendingChallenges[studentId] = challenge;
    print("[Faculty P2PManager] Generated challenge for $studentId ($endpointId): $challenge");

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
        print('[Faculty P2PManager] Challenge for $studentId ($endpointId) expired.');
        _sendResult(endpointId, false, "Challenge response timed out.");
      }
    });
  }

  Future<void> _handleChallengeResponse(Map<String, dynamic> data, String endpointId) async {
    final studentId = data['studentId'] as String?;
    final signature = data['signature'] as String?;
    final receivedSessionId = data['sessionId'] as String?;

     if (studentId == null || signature == null || _currentClassId == null) {
        print("[Faculty P2PManager] Invalid challenge response: missing data. $endpointId");
         _sendResult(endpointId, false, "Invalid response data.");
        return;
    }

    if (receivedSessionId != _currentSessionId) {
       print("[Faculty P2PManager] Session ID mismatch from $studentId ($endpointId). Expected $_currentSessionId, got $receivedSessionId");
       _sendResult(endpointId, false, "Session ID mismatch.");
       return;
    }

    final challenge = _pendingChallenges.remove(studentId);
    if (challenge == null) {
      print('[Faculty P2PManager] No pending challenge found or already expired for $studentId ($endpointId).');
      await _sendResult(endpointId, false, 'Challenge expired or invalid.');
      return;
    }
    print("[Faculty P2PManager] Verifying challenge '$challenge' for $studentId ($endpointId)");

    // Get student's public key from database (use findByStudentId for potentially simpler lookup)
    final student = await _ref.read(databaseProvider).studentDao.findByStudentId(studentId);
    // Crucially, verify they belong to the *current* class session
    if (student == null || student.classId != _currentClassId) {
      print("[Faculty P2PManager] Student $studentId not found or not in class $_currentClassId. Cannot verify. $endpointId");
      await _sendResult(endpointId, false, 'Student not found or not in this class.');
      return;
    }

    final isValid = _cryptoService.verifySignature(
      message: challenge,
      signature: signature,
      publicKeyPem: student.publicKey,
    );
     print("[Faculty P2PManager] Signature verification result for $studentId ($endpointId): $isValid");

    if (isValid) {
      // Pass the valid student object to markAttendance
      await _markAttendance(student, AttendanceStatus.present.value);
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
  // --- End Payload Handling ---


  // --- Helper Methods ---
  Future<void> _sendResult(String endpointId, bool success, String message) async {
    // Ensure the service call is awaited
    await _nearbyService.sendPayload(
        endpointId,
        {
          'type': 'attendance_result',
          'success': success,
          'message': message,
        });
     print("[Faculty P2PManager] Sent result to $endpointId: Success=$success, Msg='$message'");
  }

 Future<void> _markAttendance(Student student, String status) async {
    // Ensure session ID is valid before proceeding
    if (_currentSessionId == null || _currentClassId == null) {
      print("[Faculty P2PManager] Cannot mark attendance: session not active.");
      return;
    }

    final db = _ref.read(databaseProvider);

    // Check if a record already exists for this student in this session
    final existingRecord = await db.attendanceRecordDao.findRecordForStudentInSession(student.studentId, _currentSessionId!);

    // Only update if status is changing or record doesn't exist
    // Or specifically, only insert if not already marked present
    if (existingRecord != null && existingRecord.status == AttendanceStatus.present.value && status == AttendanceStatus.present.value) {
       print("[Faculty P2PManager] Student ${student.studentId} already marked present for session $_currentSessionId.");
       return; // Already correctly marked present
    }
     if (existingRecord != null && existingRecord.status == status) {
        print("[Faculty P2PManager] Student ${student.studentId} already marked $status for session $_currentSessionId.");
        return; // Status hasn't changed
     }


    print("[Faculty P2PManager] Marking attendance for ${student.studentId} as $status in session $_currentSessionId.");
    final record = AttendanceRecord(
      // Use existing ID if updating? Floor might handle upsert. For simplicity, just insert new/overwrite.
      recordId: existingRecord?.recordId ?? const Uuid().v4(), // Reuse ID if exists? Or generate new? Let's generate new for simplicity.
      classId: _currentClassId!,
      studentId: student.studentId,
      sessionId: _currentSessionId!,
      date: DateTime.now(), // Use current time for update/insert
      status: status,
      verifiedAt: status == AttendanceStatus.present.value ? DateTime.now() : existingRecord?.verifiedAt, // Keep original verification time if marking absent? Or set null? Set based on current status.
      createdAt: existingRecord?.createdAt ?? DateTime.now(), // Keep original creation time if exists
    );

    // Use insertOrUpdate strategy if available in DAO, otherwise insert might replace or fail based on constraints.
    // Assuming insert will handle potential conflicts or floor handles it.
    await db.attendanceRecordDao.insertAttendanceRecord(record);
  }
  // --- End Helper Methods ---


  // --- Stop Session ---
  Future<void> stopSession() async {
    print("[Faculty P2PManager] Stopping session: $_currentSessionId");
    if (_currentSessionId == null) {
       print("[Faculty P2PManager] Session already stopped or never started.");
       return; // Already stopped or never started
    }

    // Capture IDs before nullifying
    final sessionToStop = _currentSessionId!;
    final classToFinalize = _currentClassId;

    // Clean up P2P connections first
    await _nearbyService.stopAll(); // Stops advertising and disconnects all

    // Clean up internal state immediately after stopping P2P
    _pendingChallenges.clear();
    _payloadSubscription?.cancel();
    _payloadSubscription = null;
    _currentSessionId = null;
    _currentClassId = null;
    print("[Faculty P2PManager] P2P stopped and internal state cleared for session $sessionToStop.");

    // Mark remaining students as absent (using captured IDs)
    if (classToFinalize != null) {
      print("[Faculty P2PManager] Marking absent students for class $classToFinalize, session $sessionToStop.");
      final db = _ref.read(databaseProvider);
      try {
        // Find students marked present *in the session we just stopped*
        final presentRecords = await db.attendanceRecordDao.findPresentRecordsBySessionId(sessionToStop);
        final presentStudentIds = presentRecords.map((r) => r.studentId).toSet();
        print("[Faculty P2PManager] Students marked present: ${presentStudentIds.length}");

        // Find all students enrolled in the class
        final allStudents = await db.studentDao.findStudentsByClassId(classToFinalize);
         print("[Faculty P2PManager] Total students in class: ${allStudents.length}");

        // Determine who wasn't marked present
        final absentStudents = allStudents.where((s) => !presentStudentIds.contains(s.studentId));
        print("[Faculty P2PManager] Students to be marked absent: ${absentStudents.length}");

        // Mark them absent *for that specific session*
        for (final student in absentStudents) {
          // Check if an absent record already exists for this student in this session
          final existingAbsentRecord = await db.attendanceRecordDao.findRecordForStudentInSession(student.studentId, sessionToStop);
           if (existingAbsentRecord == null) {
              // Only mark absent if no record exists yet for this session
              print("[Faculty P2PManager] Marking ${student.studentId} absent.");
              await _markAttendanceAbsentOnStop(student, sessionToStop, classToFinalize); // Use helper
           } else {
              print("[Faculty P2PManager] Student ${student.studentId} already has a record for session $sessionToStop (status: ${existingAbsentRecord.status}). Skipping absent mark.");
           }
        }
         print("[Faculty P2PManager] Finished marking absent students for session $sessionToStop.");
      } catch (e) {
          print("[Faculty P2PManager] Error marking absent students: $e");
      }
    } else {
        print("[Faculty P2PManager] Cannot mark absent students: class ID was null.");
    }

    // Notify UI that session has ended
    // Ensure controller is not closed before adding event
    if (!_attendanceUpdateController.isClosed) {
      _attendanceUpdateController.add(AttendanceUpdate(
        type: AttendanceUpdateType.sessionEnded,
        message: 'Session has ended. Absentees marked.',
      ));
       print("[Faculty P2PManager] Session ended event sent.");
    } else {
         print("[Faculty P2PManager] Cannot send session ended event: Stream controller closed.");
    }
  }

   // Helper specifically for marking absent during stopSession
  Future<void> _markAttendanceAbsentOnStop(Student student, String sessionId, String classId) async {
       final db = _ref.read(databaseProvider);
       final record = AttendanceRecord(
         recordId: const Uuid().v4(),
         classId: classId,
         studentId: student.studentId,
         sessionId: sessionId,
         date: DateTime.now(), // Time session ended
         status: AttendanceStatus.absent.value,
         verifiedAt: null,
         createdAt: DateTime.now(),
       );
       await db.attendanceRecordDao.insertAttendanceRecord(record);
  }
  // --- End Stop Session ---


  void dispose() {
    print("[Faculty P2PManager] Disposing...");
    stopSession(); // Ensure session is stopped cleanly
    // Close the stream controller only when the manager itself is disposed
    // Prevent adding events after closed.
    if (!_attendanceUpdateController.isClosed) {
        _attendanceUpdateController.close();
        print("[Faculty P2PManager] Attendance stream controller closed.");
    }
  }
}

