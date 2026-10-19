import 'package:flutter/services.dart';

class DeviceCredentialService {
  const DeviceCredentialService();

  static const MethodChannel _channel = MethodChannel(
    'com.azonixnetworks.tradex_mobile/device_credential',
  );

  Future<DeviceCredential> create({
    required String credentialId,
    required bool requireBiometric,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'createCredential',
      <String, dynamic>{
        'credentialId': credentialId,
        'requireBiometric': requireBiometric,
      },
    );
    final publicKey = result?['publicKey'] as String?;
    if (publicKey == null || publicKey.isEmpty) {
      throw PlatformException(
        code: 'CREDENTIAL_CREATE_FAILED',
        message: 'The protected device credential could not be created.',
      );
    }
    return DeviceCredential(
      id: credentialId,
      algorithm: 'ES256',
      publicKey: publicKey,
    );
  }

  Future<String> sign({
    required String credentialId,
    required String message,
  }) async {
    final signature = await _channel.invokeMethod<String>(
      'sign',
      <String, dynamic>{'credentialId': credentialId, 'message': message},
    );
    if (signature == null || signature.isEmpty) {
      throw PlatformException(
        code: 'CREDENTIAL_SIGN_FAILED',
        message: 'The protected device credential could not sign in.',
      );
    }
    return signature;
  }

  Future<bool> contains(String credentialId) async {
    return await _channel.invokeMethod<bool>(
          'containsCredential',
          <String, dynamic>{'credentialId': credentialId},
        ) ??
        false;
  }

  Future<void> delete(String credentialId) {
    return _channel.invokeMethod<void>('deleteCredential', <String, dynamic>{
      'credentialId': credentialId,
    });
  }

  static String canonicalMessage({
    required String challengeId,
    required String credentialId,
    required String installationId,
    required String nonce,
  }) {
    return <String>[
      'tradex-quick-login-v1',
      challengeId.toLowerCase(),
      credentialId.toLowerCase(),
      installationId.toLowerCase(),
      nonce,
    ].join('\n');
  }
}

class DeviceCredential {
  const DeviceCredential({
    required this.id,
    required this.algorithm,
    required this.publicKey,
  });

  final String id;
  final String algorithm;
  final String publicKey;
}
