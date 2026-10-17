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

  static const String _completedFirstLoginKey =
      'tradex.auth.completed_first_login.v1';

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
      pinHash: salt == null ? null : _pinVerifier(salt, pin!),
    );

    await _storage.write(
      key: _quickUnlockKey,
      value: jsonEncode(config.toJson()),
    );
  }

  Future<QuickUnlockPinResult> verifyQuickUnlockPin(String pin) async {
    final config = await readQuickUnlock();
    if (config == null ||
        config.method != 'PIN' ||
        config.pinSalt == null ||
        config.pinHash == null) {
      return QuickUnlockPinResult.unavailable;
    }

    final now = DateTime.now();
    if (config.lockedUntil != null && now.isBefore(config.lockedUntil!)) {
      return QuickUnlockPinResult.locked;
    }

    if (_pinVerifier(config.pinSalt!, pin) == config.pinHash) {
      await _writeQuickUnlock(
        config.copyWith(failedAttempts: 0, clearLock: true),
      );
      return QuickUnlockPinResult.success;
    }

    final attempts = config.failedAttempts + 1;
    final locked = attempts >= 5;
    await _writeQuickUnlock(
      config.copyWith(
        failedAttempts: locked ? 0 : attempts,
        lockedUntil: locked ? now.add(const Duration(minutes: 5)) : null,
        clearLock: !locked,
      ),
    );
    return locked ? QuickUnlockPinResult.locked : QuickUnlockPinResult.failed;
  }

  Future<void> clearQuickUnlock() {
    return _storage.delete(key: _quickUnlockKey);
  }

  Future<bool> hasCompletedFirstLogin() async {
    return (await _storage.read(key: _completedFirstLoginKey)) == 'true';
  }

  Future<void> markFirstLoginCompleted() {
    return _storage.write(key: _completedFirstLoginKey, value: 'true');
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

  Future<void> _writeQuickUnlock(QuickUnlockConfig config) {
    return _storage.write(
      key: _quickUnlockKey,
      value: jsonEncode(config.toJson()),
    );
  }

  String _pinVerifier(String salt, String pin) {
    // Secure storage is Keystore/Keychain protected. PBKDF2-style stretching
    // also makes an extracted four-digit verifier expensive to brute-force.
    final mac = Hmac(sha256, utf8.encode(pin));
    var block = <int>[...utf8.encode(salt), 0, 0, 0, 1];
    var digest = mac.convert(block).bytes;
    final derived = List<int>.from(digest);
    for (var index = 1; index < 60000; index++) {
      digest = mac.convert(digest).bytes;
      for (var byte = 0; byte < derived.length; byte++) {
        derived[byte] ^= digest[byte];
      }
    }
    return base64UrlEncode(derived);
  }
}

enum QuickUnlockPinResult { success, failed, locked, unavailable }

class QuickUnlockConfig {
  const QuickUnlockConfig({
    required this.method,
    required this.email,
    this.pinSalt,
    this.pinHash,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final String method;
  final String email;
  final String? pinSalt;
  final String? pinHash;
  final int failedAttempts;
  final DateTime? lockedUntil;

  QuickUnlockConfig copyWith({
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) => QuickUnlockConfig(
    method: method,
    email: email,
    pinSalt: pinSalt,
    pinHash: pinHash,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLock ? null : lockedUntil ?? this.lockedUntil,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'email': email,
    'pin_salt': pinSalt,
    'pin_hash': pinHash,
    'failed_attempts': failedAttempts,
    'locked_until': lockedUntil?.toIso8601String(),
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
      failedAttempts: (json['failed_attempts'] as num?)?.toInt() ?? 0,
      lockedUntil: json['locked_until'] is String
          ? DateTime.tryParse(json['locked_until'] as String)
          : null,
    );
  }
}
