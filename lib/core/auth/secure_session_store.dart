import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

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

  static const String _quickUnlockPromptShownKey =
      'tradex.auth.quick_unlock_prompt_shown.v1';

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
    required String credentialId,
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
        (pin == null || !RegExp(r'^\d{4}$').hasMatch(pin))) {
      throw ArgumentError.value(pin, 'pin', 'A 4-digit passcode is required.');
    }

    await writeQuickUnlockMethods(
      email: email,
      credentialId: credentialId,
      biometricEnabled: normalizedMethod == 'BIOMETRIC',
      passcodeEnabled: normalizedMethod == 'PIN',
      pin: pin,
    );
  }

  Future<void> writeQuickUnlockMethods({
    required String email,
    required String credentialId,
    required bool biometricEnabled,
    required bool passcodeEnabled,
    String? pin,
    QuickUnlockConfig? previous,
  }) async {
    if (!biometricEnabled && !passcodeEnabled) {
      throw ArgumentError('At least one quick unlock method is required.');
    }

    String? pinSalt;
    String? pinHash;
    if (passcodeEnabled) {
      if (pin != null && RegExp(r'^\d{4}$').hasMatch(pin)) {
        pinSalt = _newSalt();
        pinHash = await _pinVerifier(pinSalt, pin);
      } else if (pin == null && previous?.hasPasscode == true) {
        pinSalt = previous!.pinSalt;
        pinHash = previous.pinHash;
      } else {
        throw ArgumentError.value(
          pin,
          'pin',
          'A 4-digit passcode is required.',
        );
      }
    }

    final method = biometricEnabled && passcodeEnabled
        ? 'BOTH'
        : biometricEnabled
        ? 'BIOMETRIC'
        : 'PIN';
    final config = QuickUnlockConfig(
      method: method,
      email: email,
      credentialId: credentialId,
      biometricEnabled: biometricEnabled,
      pinSalt: pinSalt,
      pinHash: pinHash,
    );
    await _writeQuickUnlock(config);
  }

  Future<QuickUnlockPinResult> verifyQuickUnlockPin(String pin) async {
    final config = await readQuickUnlock();
    if (config == null || !config.hasPasscode) {
      return QuickUnlockPinResult.unavailable;
    }

    final now = DateTime.now();
    if (config.lockedUntil != null && now.isBefore(config.lockedUntil!)) {
      return QuickUnlockPinResult.locked;
    }

    if (await _pinVerifier(config.pinSalt!, pin) == config.pinHash) {
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

  Future<bool> hasShownQuickUnlockSetupPrompt() async {
    return (await _storage.read(key: _quickUnlockPromptShownKey)) == 'true';
  }

  Future<void> markQuickUnlockSetupPromptShown() {
    return _storage.write(key: _quickUnlockPromptShownKey, value: 'true');
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

  Future<String> _pinVerifier(String salt, String pin) =>
      Isolate.run(() => _derivePinVerifier(salt, pin));
}

String _derivePinVerifier(String salt, String pin) {
  // Secure storage is Keystore/Keychain protected. PBKDF2-style stretching
  // also makes an extracted four-digit verifier expensive to brute-force.
  // Run the deliberately expensive derivation outside the UI isolate so
  // passcode setup and unlock never stall animations or touch feedback.
  final mac = Hmac(sha256, utf8.encode(pin));
  final block = <int>[...utf8.encode(salt), 0, 0, 0, 1];
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

enum QuickUnlockPinResult { success, failed, locked, unavailable }

class QuickUnlockConfig {
  const QuickUnlockConfig({
    required this.method,
    required this.email,
    required this.credentialId,
    this.biometricEnabled = false,
    this.pinSalt,
    this.pinHash,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final String method;
  final String email;
  final String credentialId;
  final bool biometricEnabled;
  final String? pinSalt;
  final String? pinHash;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get hasBiometric =>
      biometricEnabled || method == 'BIOMETRIC' || method == 'BOTH';

  bool get hasPasscode => pinSalt != null && pinHash != null;

  QuickUnlockConfig copyWith({
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) => QuickUnlockConfig(
    method: method,
    email: email,
    credentialId: credentialId,
    biometricEnabled: biometricEnabled,
    pinSalt: pinSalt,
    pinHash: pinHash,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLock ? null : lockedUntil ?? this.lockedUntil,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 2,
    'method': method,
    'email': email,
    'credential_id': credentialId,
    'biometric_enabled': hasBiometric,
    'pin_salt': pinSalt,
    'pin_hash': pinHash,
    'failed_attempts': failedAttempts,
    'locked_until': lockedUntil?.toIso8601String(),
  };

  factory QuickUnlockConfig.fromJson(Map<String, dynamic> json) {
    final method = json['method'] as String?;
    final email = json['email'] as String?;
    final credentialId = json['credential_id'] as String?;
    if ((method != 'PIN' && method != 'BIOMETRIC' && method != 'BOTH') ||
        email == null ||
        email.isEmpty ||
        credentialId == null ||
        credentialId.isEmpty) {
      throw const FormatException();
    }
    return QuickUnlockConfig(
      method: method!,
      email: email,
      credentialId: credentialId,
      biometricEnabled:
          json['biometric_enabled'] as bool? ??
          (method == 'BIOMETRIC' || method == 'BOTH'),
      pinSalt: json['pin_salt'] as String?,
      pinHash: json['pin_hash'] as String?,
      failedAttempts: (json['failed_attempts'] as num?)?.toInt() ?? 0,
      lockedUntil: json['locked_until'] is String
          ? DateTime.tryParse(json['locked_until'] as String)
          : null,
    );
  }
}
