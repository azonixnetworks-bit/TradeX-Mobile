import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'tradex.auth.session.v1';

  static const String _installationKey = 'tradex.device.installation_id.v1';

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

  Future<String?> readInstallationId() {
    return _storage.read(key: _installationKey);
  }

  Future<void> writeInstallationId(String value) {
    return _storage.write(key: _installationKey, value: value);
  }
}
