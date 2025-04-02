import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityUtils {
  static final _storage = const FlutterSecureStorage();
  static final _random = Random.secure();

  // Códigos de acesso pré-definidos (apenas para desenvolvimento)
  static const String adminCode = 'admin2025';
  static const String teacherCode = 'prof2025';
  static const String _staticPepper = 'S3cur3P3pp3r2025!@#'; // Pepper fixo
  static const String _staticSalt = 'St4t1cS4lt2025!@#'; // Salt fixo

  // Verifica força da senha com requisitos mais rigorosos
  static Map<String, dynamic> checkPasswordStrength(String password) {
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );
    bool hasMinLength = password.length >= 12;
    bool hasNoCommonPatterns = !_containsCommonPatterns(password);
    bool hasNoSequentialChars = !_containsSequentialChars(password);

    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialCharacters) strength++;
    if (hasMinLength) strength++;
    if (hasNoCommonPatterns) strength++;
    if (hasNoSequentialChars) strength++;

    return {
      'isStrong': strength >= 6,
      'hasUppercase': hasUppercase,
      'hasLowercase': hasLowercase,
      'hasDigits': hasDigits,
      'hasSpecialCharacters': hasSpecialCharacters,
      'hasMinLength': hasMinLength,
      'hasNoCommonPatterns': hasNoCommonPatterns,
      'hasNoSequentialChars': hasNoSequentialChars,
      'strength': strength,
    };
  }

  static String hashAccessCode(String code) {
    final bytes = utf8.encode(code + _staticSalt + _staticPepper);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool _containsCommonPatterns(String password) {
    final commonPatterns = [
      '123',
      '321',
      'abc',
      'cba',
      'qwerty',
      'admin',
      'password',
      'letmein',
    ];
    return commonPatterns.any(
      (pattern) => password.toLowerCase().contains(pattern.toLowerCase()),
    );
  }

  static bool _containsSequentialChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password.codeUnitAt(i + 1) == password.codeUnitAt(i) + 1 &&
          password.codeUnitAt(i + 2) == password.codeUnitAt(i) + 2) {
        return true;
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceData = await deviceInfoPlugin.deviceInfo;
      return {
        ...deviceData.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
        'fingerprint': await _generateDeviceFingerprint(),
      };
    } catch (e) {
      return {'error': 'Could not get device info: $e'};
    }
  }

  static Future<String> _generateDeviceFingerprint() async {
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    final fingerprint =
        deviceInfo.toMap().toString() + DateTime.now().toString();
    return sha256.convert(utf8.encode(fingerprint)).toString();
  }

  static String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt + _staticPepper);
    final digest = sha256.convert(bytes);
    return '$digest:$salt';
  }

  static String _generateSalt() {
    return base64Url.encode(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    );
  }

  static Future<void> storeAuthToken(String token) async {
    final encryptedToken = _encryptData(token);
    await _storage.write(key: 'auth_token', value: encryptedToken);
  }

  static Future<String?> getAuthToken() async {
    final encryptedToken = await _storage.read(key: 'auth_token');
    return encryptedToken != null ? _decryptData(encryptedToken) : null;
  }

  static String _encryptData(String data) {
    // TODO: Implement AES encryption
    return data;
  }

  static String _decryptData(String encryptedData) {
    // TODO: Implement AES decryption
    return encryptedData;
  }

  static Future<void> clearSecureStorage() async {
    await _storage.deleteAll();
    await FirebaseAuth.instance.signOut();
  }

  static Future<bool> validateAccessCode(String role, String inputCode) async {
    try {
      final expectedCode = role == 'admin' ? adminCode : teacherCode;

      final hashedInput = hashAccessCode(inputCode);
      final hashedExpected = hashAccessCode(expectedCode);

      return hashedInput == hashedExpected;
    } catch (e) {
      print('Erro na validação do código: $e');
      return false;
    }
  }
}
