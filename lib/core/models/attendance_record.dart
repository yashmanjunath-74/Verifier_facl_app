
import 'package:floor/floor.dart';


@entity
class AttendanceRecord {
  @primaryKey
  final int? id;
  @ColumnInfo(name: 'record_id')
  final String recordId;
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'session_id')
  final String sessionId;
  @ColumnInfo(name: 'date')
  final DateTime date;
  @ColumnInfo(name: 'status')
  final String status; // 'present' or 'absent'
  @ColumnInfo(name: 'verified_at')
  final DateTime? verifiedAt;
  @ColumnInfo(name: 'created_at')
  final DateTime createdAt;

  AttendanceRecord({
    this.id,
    required this.recordId,
    required this.classId,
    required this.studentId,
    required this.sessionId,
    required this.date,
    required this.status,
    this.verifiedAt,
    required this.createdAt,
  });
}