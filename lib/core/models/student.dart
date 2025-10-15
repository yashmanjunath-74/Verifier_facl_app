
import 'package:floor/floor.dart';

@entity
class Student {
  @primaryKey
  final int? id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'name')
  final String name;
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'public_key')
  final String publicKey;
  @ColumnInfo(name: 'enrolled_at')
  final DateTime enrolledAt;
  @ColumnInfo(name: 'created_at')
  final DateTime createdAt;

  Student({
    this.id,
    required this.studentId,
    required this.name,
    required this.classId,
    required this.publicKey,
    required this.enrolledAt,
    required this.createdAt,
  });
}