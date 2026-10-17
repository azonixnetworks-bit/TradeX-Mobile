import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'tradex.auth.session.v1';

  static const String _installationKey = 'tradex.device.installation_id.v1';

  static const String _quickUnlockKey = 'tradex.auth.quick_unlock.v1';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        await clearSession();
        return null;
      }

      return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> writeSession(AuthSession session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> clearSession() {
    return _storage.delete(key: _sessionKey);
  }

  Future<QuickUnlockConfig?> readQuickUnlock() async {
    final raw = await _storage.read(key: _quickUnlockKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException();
      return QuickUnlockConfig.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await clearQuickUnlock();
      return null;
    }
  }

  Future<void> writeQuickUnlock({
    required String method,
    required String email,
    String? pin,
  }) async {
    final normalizedMethod = method.toUpperCase();
    if (normalizedMethod != 'PIN' && normalizedMethod != 'BIOMETRIC') {
      throw ArgumentError.value(
        method,
        'method',
        'Unsupported quick unlock method.',
      );
    }
    if (normalizedMethod == 'PIN' &&
        (pin == null || !RegExp(r'^\\d{4}$').hasMatch(pin))) {
      throw ArgumentError.value(pin, 'pin', 'A 4-digit passcode is required.');
    }

    final salt = normalizedMethod == 'PIN' ? _newSalt() : null;
    final config = QuickUnlockConfig(
      method: normalizedMethod,
      email: email,
      pinSalt: salt,
      pinHash: salt == null ? null : _pinHash(salt, pin!),
    );

    await _storage.write(
      key: _quickUnlockKey,
      value: jsonEncode(config.toJson()),
    );
  }

  Future<bool> verifyQuickUnlockPin(String pin) async {
    final config = await readQuickUnlock();
    if (config == null ||
        config.method != 'PIN' ||
        config.pinSalt == null ||
        config.pinHash == null) {
      return false;
    }
    return _pinHash(config.pinSalt!, pin) == config.pinHash;
  }

  Future<void> clearQuickUnlock() {
    return _storage.delete(key: _quickUnlockKey);
  }

  Future<String?> readInstallationId() {
    return _storage.read(key: _installationKey);
  }

  Future<void> writeInstallationId(String value) {
    return _storage.write(key: _installationKey, value: value);
  }

  String _newSalt() {
    final random = Random.secure();
    final values = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  String _pinHash(String salt, String pin) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}

class QuickUnlockConfig {
  const QuickUnlockConfig({
    required this.method,
    required this.email,
    this.pinSalt,
    this.pinHash,
  });

  final String method;
  final String email;
  final String? pinSalt;
  final String? pinHash;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'email': email,
    'pin_salt': pinSalt,
    'pin_hash': pinHash,
  };

  factory QuickUnlockConfig.fromJson(Map<String, dynamic> json) {
    final method = json['method'] as String?;
    final email = json['email'] as String?;
    if ((method != 'PIN' && method != 'BIOMETRIC') ||
        email == null ||
        email.isEmpty) {
      throw const FormatException();
    }
    return QuickUnlockConfig(
      method: method!,
      email: email,
      pinSalt: json['pin_salt'] as String?,
      pinHash: json['pin_hash'] as String?,
    );
  }
}
