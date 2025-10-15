
import 'package:floor/floor.dart';

@entity
class ClassGroup {
  @primaryKey
  final int? id;
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'class_name')
  final String className;
  @ColumnInfo(name: 'course_code')
  final String courseCode;
  @ColumnInfo(name: 'faculty_id')
  final String facultyId;
  @ColumnInfo(name: 'created_at')
  final DateTime createdAt;

  ClassGroup({
    this.id,
    required this.classId,
    required this.className,
    required this.courseCode,
    required this.facultyId,
    required this.createdAt,
  });
}