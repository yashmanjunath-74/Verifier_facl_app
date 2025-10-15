
import 'package:floor/floor.dart';
import 'package:verifier_facl/core/models/faculty.dart';

@dao
abstract class FacultyDao {
  @Query('SELECT * FROM Faculty WHERE username = :username')
  Future<Faculty?> findFacultyByUsername(String username);

  @Query('SELECT * FROM Faculty LIMIT 1')
  Future<Faculty?> findFirstFaculty();

  @insert
  Future<void> insertFaculty(Faculty faculty);

  @Query('SELECT COUNT(*) FROM Faculty')
  Future<int?> getFacultyCount();
}