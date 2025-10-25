import 'package:floor/floor.dart';
import 'package:verifier_facl/core/models/attendance_record.dart'; // Ensure correct import path

@dao
abstract class AttendanceRecordDao {
  @Insert(onConflict: OnConflictStrategy.replace) // Use replace strategy for insert/update
  Future<void> insertAttendanceRecord(AttendanceRecord record);

  @Query('SELECT * FROM AttendanceRecord WHERE session_id = :sessionId AND status = "present"')
  Future<List<AttendanceRecord>> findPresentRecordsBySessionId(String sessionId);

  // FIX: Revert to the simpler query that Floor can handle for streams.
  // The DISTINCT logic will need to be handled in Dart code later if needed.
  @Query('SELECT * FROM AttendanceRecord WHERE class_id = :classId GROUP BY session_id ORDER BY date DESC')
  Stream<List<AttendanceRecord>> watchSessionsByClassId(String classId);


  @Query('SELECT * FROM AttendanceRecord WHERE session_id = :sessionId')
  Future<List<AttendanceRecord>> findRecordsBySessionId(String sessionId);
  
  @Query('SELECT * FROM AttendanceRecord WHERE session_id = :sessionId ORDER BY date DESC') // Added order by
  Stream<List<AttendanceRecord>> watchRecordsBySessionId(String sessionId);

  // Query method to find a specific student's record within a session
  @Query('SELECT * FROM AttendanceRecord WHERE student_id = :studentId AND session_id = :sessionId LIMIT 1')
  Future<AttendanceRecord?> findRecordForStudentInSession(String studentId, String sessionId);
}

// Example Data class (keep for potential future use, but not used by the stream now)
class SessionInfo {
  @ColumnInfo(name: 'session_id')
  final String sessionId;
  @ColumnInfo(name: 'session_date')
  final int sessionDate; // Floor needs primitive types from query results usually

  SessionInfo(this.sessionId, this.sessionDate);

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(sessionDate);
}