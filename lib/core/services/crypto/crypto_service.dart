import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:crypton/crypton.dart';

class CryptoService {
  /// Generates a random, cryptographically secure salt.
  String generateRandomSalt(int length) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashes a password using HMAC-SHA256 with a given salt.
  String hashPassword(String password, String salt) {
    const codec = Utf8Encoder();
    final key = codec.convert(password);
    final saltBytes = base64Decode(salt);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(saltBytes);
    return digest.toString();
  }

  /// Generates a secure, random challenge string for the P2P protocol.
  String generateChallenge() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Verifies an Ed25519 signature against a message and a public key.
  bool verifySignature({
    required String message,
    required String signature,
    required String publicKeyPem,
  }) {
    try {
      final publicKey = ECPublicKey.fromString(publicKeyPem);
      // This method correctly takes the Base64URL string (signature)
      // and the original raw message string (message) to verify.
      return publicKey.verifySignature(signature, message);
    } catch (e) {
      print('Signature verification error: $e');
      return false;
    }
  }

  /// Parses student data from a JSON string (from a QR code).
  Map<String, String>? parseStudentQR(String qrData) {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      // Check if all required keys are present in the JSON
      if (decoded.containsKey('studentId') &&
          decoded.containsKey('name') &&
          decoded.containsKey('publicKey')) {
        return {
          'studentId': decoded['studentId'] as String,
          'name': decoded['name'] as String,
          'publicKey': decoded['publicKey'] as String,
        };
      }
    } catch (e) {
      // Catches errors if qrData is not valid JSON
      print('QR parsing error: $e');
    }
    // Return null if parsing fails or keys are missing
    return null;
  }
}

