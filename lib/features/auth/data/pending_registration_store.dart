import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/registration_session.dart';

/// A pending registration session is NOT an authenticated user session.
/// Credentials and passwords are never persisted here.
class PendingRegistrationSnapshot {
  const PendingRegistrationSnapshot({
    required this.session,
    required this.name,
    required this.email,
    required this.phone,
  });

  final RegistrationSession session;
  final String name;
  final String email;
  final String phone;
}

class PendingRegistrationStore {
  const PendingRegistrationStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'tradex_pending_registration_v1';

  Future<void> save({
    required RegistrationSession session,
    required String name,
    required String email,
    required String phone,
  }) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'id': session.id,
        'token': session.token,
        'expires_at': session.expiresAt.toUtc().toIso8601String(),
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );
  }

  Future<PendingRegistrationSnapshot?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final expiration = DateTime.parse(data['expires_at'] as String);
      if (!expiration.isAfter(DateTime.now()) ||
          (data['id'] as String).isEmpty ||
          (data['token'] as String).isEmpty) {
        await clear();
        return null;
      }

      return PendingRegistrationSnapshot(
        session: RegistrationSession(
          id: data['id'] as String,
          token: data['token'] as String,
          expiresAt: expiration,
        ),
        name: data['name'] as String,
        email: data['email'] as String,
        phone: data['phone'] as String,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
