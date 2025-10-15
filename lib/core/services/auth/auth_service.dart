
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:verifier_facl/core/models/faculty.dart';
import 'package:verifier_facl/core/services/crypto_service.dart';
import 'package:verifier_facl/core/services/database/app_database.dart';

class AuthService {
  final AppDatabase _db;
  final CryptoService _cryptoService;
  final FlutterSecureStorage _secureStorage;
  static const _sessionKey = 'faculty_session_token';

  AuthService(this._db, this._cryptoService, this._secureStorage);

  Future<Faculty?> get currentFaculty async {
    final token = await _secureStorage.read(key: _sessionKey);
    if (token == null) return null;
    // In a real app, token would map to a user ID. Here we assume only one user.
    return _db.facultyDao.findFirstFaculty();
  }
  
  Future<bool> hasFacultyAccount() async {
    final count = await _db.facultyDao.getFacultyCount() ?? 0;
    return count > 0;
  }

  Future<Faculty> signUp(String username, String password) async {
    final salt = _cryptoService.generateRandomSalt(32);
    final passwordHash = _cryptoService.hashPassword(password, salt);
    
    final newFaculty = Faculty(
      facultyId: const Uuid().v4(),
      username: username,
      passwordHash: passwordHash,
      passwordSalt: salt,
      createdAt: DateTime.now(),
    );
    await _db.facultyDao.insertFaculty(newFaculty);
    return newFaculty;
  }

  Future<Faculty?> login(String username, String password) async {
    final faculty = await _db.facultyDao.findFacultyByUsername(username);
    if (faculty == null) return null;

    final hash = _cryptoService.hashPassword(password, faculty.passwordSalt);
    if (hash == faculty.passwordHash) {
      final token = const Uuid().v4();
      await _secureStorage.write(key: _sessionKey, value: token);
      return faculty;
    }
    return null;
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _sessionKey);
  }
}