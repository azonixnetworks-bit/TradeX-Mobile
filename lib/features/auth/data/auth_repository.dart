import 'package:uuid/uuid.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/device_credential_service.dart';
import '../../../core/auth/secure_session_store.dart';
import '../../../core/device/device_identity.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';

class AuthRepository {
  AuthRepository(
    this._apiClient,
    this._sessionStore,
    this._deviceIdentity, {
    DeviceCredentialService credentialService = const DeviceCredentialService(),
  }) : // Named publicly so tests can inject a platform-channel fake.
       // ignore: prefer_initializing_formals
       _credentialService = credentialService;

  final TradeXApiClient _apiClient;
  final SecureSessionStore _sessionStore;
  final DeviceIdentity _deviceIdentity;
  final DeviceCredentialService _credentialService;
  final Uuid _uuid = const Uuid();

  /// Restores a session only after local Quick Unlock has succeeded.
  ///
  /// A session created without "Remember this device" deliberately has no
  /// Quick Unlock configuration. It is cleared at the next app launch rather
  /// than becoming a silent persistent login.
  Future<AuthSession?> restoreRememberedSession() async {
    if (await _sessionStore.readQuickUnlock() == null) {
      await _sessionStore.clearSession();
      return null;
    }

    return _restoreStoredSession();
  }

  Future<AuthSession?> restoreSessionAfterQuickUnlock() async {
    final config = await _sessionStore.readQuickUnlock();
    if (config == null) return null;
    return quickLogin(config);
  }

  Future<AuthSession?> _restoreStoredSession() async {
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
    String? quickUnlockMethod,
    String? quickUnlockPin,
  }) async {
    final device = await _deviceIdentity.load();
    final previousQuickUnlock = await _sessionStore.readQuickUnlock();
    DeviceCredential? credential;

    if (quickUnlockMethod != null) {
      credential = await _credentialService.create(
        credentialId: _uuid.v4(),
        requireBiometric: quickUnlockMethod == 'BIOMETRIC',
      );
    }

    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),

      'password': password,

      ...device.toApiJson(),

      if (totpCode != null && totpCode.trim().isNotEmpty)
        'totp_code': totpCode.trim(),

      if (recoveryCode != null && recoveryCode.trim().isNotEmpty)
        'recovery_code': recoveryCode.trim(),

      if (quickUnlockMethod?.isNotEmpty == true)
        'quick_unlock_method': quickUnlockMethod!,

      if (credential != null) ...<String, dynamic>{
        'quick_unlock_credential_id': credential.id,
        'quick_unlock_credential_algorithm': credential.algorithm,
        'quick_unlock_credential_public_key': credential.publicKey,
      },
    };

    Map<String, dynamic> response;
    try {
      response = await _apiClient.publicPost('/api/v1/auth/login', payload);
    } catch (_) {
      if (credential != null) await _credentialService.delete(credential.id);
      rethrow;
    }

    final rawData = response['data'];

    if (rawData is! Map) {
      throw const ApiException(
        message: 'TradeX returned an invalid login response.',
      );
    }

    final data = Map<String, dynamic>.from(rawData);
    final session = _sessionFrom(data);

    await _sessionStore.writeSession(session);

    if (credential != null &&
        data['quick_unlock_method'] == quickUnlockMethod) {
      try {
        await _sessionStore.writeQuickUnlock(
          method: quickUnlockMethod!,
          email: email.trim().toLowerCase(),
          credentialId: credential.id,
          pin: quickUnlockPin,
        );
        if (previousQuickUnlock != null &&
            previousQuickUnlock.credentialId != credential.id) {
          await _credentialService.delete(previousQuickUnlock.credentialId);
        }
      } catch (_) {
        await _bestEffortForgetServerCredential();
        try {
          await _apiClient.postJson('/api/v1/auth/logout', const {});
        } catch (_) {
          // The local session is cleared below even if the network drops.
        }
        await _sessionStore.clearSession();
        await _credentialService.delete(credential.id);
        rethrow;
      }
    } else if (credential != null) {
      await _credentialService.delete(credential.id);
    } else if (previousQuickUnlock != null) {
      await _credentialService.delete(previousQuickUnlock.credentialId);
      await _sessionStore.clearQuickUnlock();
    }

    return session;
  }

  Future<void> logout({bool forgetDevice = false}) async {
    final quickUnlock = await _sessionStore.readQuickUnlock();
    try {
      if (forgetDevice) {
        await _bestEffortForgetServerCredential();
      }
      await _apiClient.postJson(
        '/api/v1/auth/logout',
        const <String, dynamic>{},
      );
    } finally {
      await _sessionStore.clearSession();
      if (forgetDevice && quickUnlock != null) {
        await _credentialService.delete(quickUnlock.credentialId);
        await _sessionStore.clearQuickUnlock();
      }
    }
  }

  Future<void> logoutAll() async {
    final quickUnlock = await _sessionStore.readQuickUnlock();
    try {
      await _apiClient.postJson('/api/v1/auth/logout-all', const {});
    } finally {
      await _sessionStore.clearSession();
      if (quickUnlock != null) {
        await _credentialService.delete(quickUnlock.credentialId);
      }
      await _sessionStore.clearQuickUnlock();
    }
  }

  Future<void> clearLocalSession() {
    return _sessionStore.clearSession();
  }

  Future<QuickUnlockConfig?> quickUnlockConfiguration() {
    return _sessionStore.readQuickUnlock();
  }

  Future<Map<String, dynamic>> quickUnlockStatus() async {
    final response = await _apiClient.getJson('/api/v1/security/quick-unlock');
    final data = response['data'];
    if (data is! Map) return <String, dynamic>{};

    final status = Map<String, dynamic>.from(data);
    final local = await _sessionStore.readQuickUnlock();
    final serverCredentialId = status['credential_id']?.toString();

    if (status['enabled'] != true) {
      if (local != null) {
        await _credentialService.delete(local.credentialId);
        await _sessionStore.clearQuickUnlock();
      }
      return status;
    }

    final localReady =
        local != null &&
        local.credentialId == serverCredentialId &&
        await _credentialService.contains(local.credentialId);
    if (!localReady) {
      if (local != null) {
        await _credentialService.delete(local.credentialId);
        await _sessionStore.clearQuickUnlock();
      }
      status['enabled'] = false;
      status['enrolled'] = false;
      status['requires_reenrollment'] = true;
      status['local_state'] = 'CREDENTIAL_MISSING';
    }

    return status;
  }

  Future<void> configureQuickUnlock({
    required bool enabled,
    String? method,
    required String totpCode,
    String? pin,
  }) async {
    if (!enabled) {
      await _apiClient.patchJson('/api/v1/security/quick-unlock', {
        'enabled': false,
        'totp_code': totpCode,
      });
      final previous = await _sessionStore.readQuickUnlock();
      if (previous != null) {
        await _credentialService.delete(previous.credentialId);
      }
      await _sessionStore.clearQuickUnlock();
      return;
    }

    final credential = await _credentialService.create(
      credentialId: _uuid.v4(),
      requireBiometric: method == 'BIOMETRIC',
    );
    try {
      await _apiClient.patchJson('/api/v1/security/quick-unlock', {
        'enabled': true,
        'method': method,
        'totp_code': totpCode,
        'credential_id': credential.id,
        'credential_algorithm': credential.algorithm,
        'credential_public_key': credential.publicKey,
      });
    } catch (_) {
      await _credentialService.delete(credential.id);
      rethrow;
    }

    try {
      final previous = await _sessionStore.readQuickUnlock();
      await _sessionStore.writeQuickUnlock(
        method: method!,
        email:
            (await _sessionStore.readSession())?.user['email']?.toString() ??
            '',
        credentialId: credential.id,
        pin: pin,
      );
      if (previous != null && previous.credentialId != credential.id) {
        await _credentialService.delete(previous.credentialId);
      }
    } catch (_) {
      await _bestEffortForgetServerCredential();
      await _credentialService.delete(credential.id);
      rethrow;
    }
  }

  Future<AuthSession> quickLogin(QuickUnlockConfig config) async {
    final device = await _deviceIdentity.load();
    if (!await _credentialService.contains(config.credentialId)) {
      await clearLocalQuickUnlock();
      throw const ApiException(
        message: 'Quick login is no longer available on this device. Sign in with email, password and authenticator code to set it up again.',
        statusCode: 401,
        code: 'QUICK_UNLOCK_CREDENTIAL_MISSING',
      );
    }

    final challengeResponse = await _apiClient.publicPost(
      '/api/v1/auth/quick-unlock/challenge',
      <String, dynamic>{
        'credential_id': config.credentialId,
        'installation_id': device.installationId,
      },
    );
    final challenge = Map<String, dynamic>.from(
      challengeResponse['data'] as Map,
    );
    final challengeId = challenge['challenge_id'] as String;
    final nonce = challenge['nonce'] as String;
    final message = DeviceCredentialService.canonicalMessage(
      challengeId: challengeId,
      credentialId: config.credentialId,
      installationId: device.installationId,
      nonce: nonce,
    );
    final signature = await _credentialService.sign(
      credentialId: config.credentialId,
      message: message,
    );

    final verifyResponse = await _apiClient.publicPost(
      '/api/v1/auth/quick-unlock/verify',
      <String, dynamic>{
        'challenge_id': challengeId,
        'credential_id': config.credentialId,
        'installation_id': device.installationId,
        'nonce': nonce,
        'signature': signature,
      },
    );
    final data = Map<String, dynamic>.from(verifyResponse['data'] as Map);
    final session = _sessionFrom(data);
    await _sessionStore.writeSession(session);
    return session;
  }

  Future<void> clearLocalQuickUnlock() async {
    final config = await _sessionStore.readQuickUnlock();
    if (config != null) await _credentialService.delete(config.credentialId);
    await _sessionStore.clearQuickUnlock();
    await _sessionStore.clearSession();
  }

  AuthSession _sessionFrom(Map<String, dynamic> data) {
    final now = DateTime.now();
    return AuthSession(
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
  }

  Future<void> _bestEffortForgetServerCredential() async {
    try {
      await _apiClient.deleteJson('/api/v1/security/quick-unlock');
    } catch (_) {
      // Local key removal still prevents this installation from signing.
    }
  }

  Future<bool> hasCompletedFirstLogin() {
    return _sessionStore.hasCompletedFirstLogin();
  }

  Future<void> markFirstLoginCompleted() {
    return _sessionStore.markFirstLoginCompleted();
  }
}
