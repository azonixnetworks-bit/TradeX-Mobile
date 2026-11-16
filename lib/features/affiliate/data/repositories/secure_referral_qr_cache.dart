import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/referral_qr_cache.dart';

final class SecureReferralQrCache implements ReferralQrCache {
  SecureReferralQrCache({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String> resolve({required String key, required String payload}) async {
    final storageKey = 'tradex.affiliate.referral_qr.$key';
    try {
      final cached = await _storage.read(key: storageKey);
      if (cached == payload) return cached!;
      await _storage.write(key: storageKey, value: payload);
    } catch (_) {
      // Secure-storage availability must never block referral sharing.
    }
    return payload;
  }
}
