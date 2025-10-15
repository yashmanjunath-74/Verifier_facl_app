
import 'package:floor/floor.dart';
import 'package:verifier_facl/core/models/attendance_record.dart';

@dao
abstract class AttendanceRecordDao {
  @insert
  Future<void> insertAttendanceRecord(AttendanceRecord record);

  @Query('SELECT * FROM AttendanceRecord WHERE session_id = :sessionId AND status = "present"')
  Future<List<AttendanceRecord>> findPresentRecordsBySessionId(String sessionId);

  @Query('SELECT * FROM AttendanceRecord WHERE class_id = :classId GROUP BY session_id ORDER BY date DESC')
  Stream<List<AttendanceRecord>> watchSessionsByClassId(String classId);

  @Query('SELECT * FROM AttendanceRecord WHERE session_id = :sessionId')
  Future<List<AttendanceRecord>> findRecordsBySessionId(String sessionId);
  
  @Query('SELECT * FROM AttendanceRecord WHERE session_id = :sessionId')
  Stream<List<AttendanceRecord>> watchRecordsBySessionId(String sessionId);
}