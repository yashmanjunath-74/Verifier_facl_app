
import 'package:floor/floor.dart';
import 'package:verifier_facl/core/models/class_group.dart';

@dao
abstract class ClassGroupDao {
  @Query('SELECT * FROM ClassGroup WHERE faculty_id = :facultyId ORDER BY created_at DESC')
  Stream<List<ClassGroup>> watchAllClassesByFacultyId(String facultyId);

  @Query('SELECT * FROM ClassGroup WHERE class_id = :classId')
  Future<ClassGroup?> findClassById(String classId);

  @insert
  Future<void> insertClass(ClassGroup classGroup);

  @update
  Future<void> updateClass(ClassGroup classGroup);

  @delete
  Future<void> deleteClass(ClassGroup classGroup);
}