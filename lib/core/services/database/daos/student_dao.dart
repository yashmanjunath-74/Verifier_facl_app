
import 'package:floor/floor.dart';
import 'package:verifier_facl/core/models/student.dart';

@dao
abstract class StudentDao {
  @Query('SELECT * FROM Student WHERE class_id = :classId ORDER BY name ASC')
  Stream<List<Student>> watchStudentsByClassId(String classId);

  @Query('SELECT * FROM Student WHERE class_id = :classId')
  Future<List<Student>> findStudentsByClassId(String classId);

  @Query('SELECT * FROM Student WHERE student_id = :studentId AND class_id = :classId')
  Future<Student?> findStudentByStudentIdAndClassId(String studentId, String classId);

  @Query('SELECT * FROM Student WHERE student_id = :studentId LIMIT 1')
  Future<Student?> findByStudentId(String studentId);

  @insert
  Future<void> insertStudent(Student student);

  @delete
  Future<void> deleteStudent(Student student);

  @Query('DELETE FROM Student WHERE class_id = :classId')
  Future<void> deleteStudentsByClassId(String classId);
}