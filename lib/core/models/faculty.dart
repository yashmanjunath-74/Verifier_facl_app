
import 'package:floor/floor.dart';

@entity
class Faculty {
  @primaryKey
  final int? id;
  @ColumnInfo(name: 'faculty_id')
  final String facultyId;
  @ColumnInfo(name: 'username')
  final String username;
  @ColumnInfo(name: 'password_hash')
  final String passwordHash;
  @ColumnInfo(name: 'password_salt')
  final String passwordSalt;
  @ColumnInfo(name: 'created_at')
  final DateTime createdAt;

  Faculty({
    this.id,
    required this.facultyId,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
  });
}