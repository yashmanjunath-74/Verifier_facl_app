
class AppConstants {
  // Database
  static const String databaseName = 'verifier_faculty.db';
  static const int databaseVersion = 2;

  // BLE Configuration
  static const String bleServiceUuid = '12345678-1234-1234-1234-123456789ABC';

  // Session Configuration
  static const Duration challengeTimeout = Duration(seconds: 30);
  
  // Security
  static const int passwordSaltLength = 32;
  static const int challengeLength = 64;

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
}

enum AttendanceStatus {
  present('present'),
  absent('absent'),
  pending('pending');

  const AttendanceStatus(this.value);
  final String value;
}

enum SessionState {
  idle,
  starting,
  active,
  stopping,
  error
}