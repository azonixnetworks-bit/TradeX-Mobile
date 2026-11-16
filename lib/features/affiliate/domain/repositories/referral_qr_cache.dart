abstract interface class ReferralQrCache {
  Future<String> resolve({required String key, required String payload});
}

final class MemoryReferralQrCache implements ReferralQrCache {
  MemoryReferralQrCache();

  final Map<String, String> _values = <String, String>{};

  @override
  Future<String> resolve({required String key, required String payload}) async {
    final cached = _values[key];
    if (cached == payload) return cached!;
    _values[key] = payload;
    return payload;
  }
}
