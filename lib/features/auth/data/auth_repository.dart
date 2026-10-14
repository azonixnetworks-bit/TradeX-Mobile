import '../../../core/auth/auth_session.dart';
import '../../../core/auth/secure_session_store.dart';
import '../../../core/device/device_identity.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';

class AuthRepository {
  AuthRepository(
    this._apiClient,
    this._sessionStore,
    this._deviceIdentity,
  );

  final TradeXApiClient _apiClient;
  final SecureSessionStore _sessionStore;
  final DeviceIdentity _deviceIdentity;

  Future<AuthSession?> restoreSession() async {
    final session = await _sessionStore.readSession();

    if (session == null) {
      return null;
    }

    if (session.refreshTokenExpired) {
      await _sessionStore.clearSession();
      return null;
    }

    if (session.accessTokenExpired) {
      try {
        return await _apiClient.refreshSession();
      } on ApiException catch (error) {
        if (error.shouldClearSession) {
          await _sessionStore.clearSession();
          return null;
        }

        rethrow;
      }
    }

    return session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    String? totpCode,
    String? recoveryCode,
  }) async {
    final device = await _deviceIdentity.load();

    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),

      'password': password,

      ...device.toApiJson(),

      if (totpCode != null && totpCode.trim().isNotEmpty)
        'totp_code': totpCode.trim(),

      if (recoveryCode != null && recoveryCode.trim().isNotEmpty)
        'recovery_code': recoveryCode.trim(),
    };

    final response = await _apiClient.publicPost('/api/v1/auth/login', payload);

    final rawData = response['data'];

    if (rawData is! Map) {
      throw const ApiException(
        message: 'TradeX returned an invalid login response.',
      );
    }

    final data = Map<String, dynamic>.from(rawData);

    final now = DateTime.now();

    final session = AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      accessExpiresAt: now.add(
        Duration(seconds: (data['expires_in'] as num).toInt()),
      ),
      refreshExpiresAt: now.add(
        Duration(seconds: (data['refresh_expires_in'] as num).toInt()),
      ),
      sessionUuid: data['session_uuid'] as String,
      user: Map<String, dynamic>.from(data['user'] as Map),
    );

    await _sessionStore.writeSession(session);

    return session;
  }

  Future<void> logout() async {
    try {
      await _apiClient.postJson(
        '/api/v1/auth/logout',
        const <String, dynamic>{},
      );
    } finally {
      await _sessionStore.clearSession();
    }
  }

  Future<void> clearLocalSession() {
    return _sessionStore.clearSession();
  }
}