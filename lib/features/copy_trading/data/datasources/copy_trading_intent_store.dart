import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/tradex_api_client.dart';
import '../models/copy_trading_models.dart';

abstract interface class CopyTradingIntentStore {
  Future<void> write(String marketId, CopyTradeJson value);
  Future<CopyTradeJson?> read(String marketId);
  Future<void> delete(String marketId);
}

final class SecureCopyTradingIntentStore implements CopyTradingIntentStore {
  SecureCopyTradingIntentStore(this._apiClient, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final TradeXApiClient _apiClient;
  final FlutterSecureStorage _storage;

  Future<String> _key(String marketId) async {
    final accountKey = await _apiClient.currentAccountStorageKey();
    return 'tradex.copy_trading.intent.v1.${accountKey ?? 'signed-out'}.$marketId';
  }

  @override
  Future<void> write(String marketId, CopyTradeJson value) async {
    await _storage.write(key: await _key(marketId), value: jsonEncode(value));
  }

  @override
  Future<CopyTradeJson?> read(String marketId) async {
    final raw = await _storage.read(key: await _key(marketId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final value = Map<String, dynamic>.from(decoded);
      final expiry = DateTime.tryParse(value['expires_at']?.toString() ?? '');
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        await delete(marketId);
        return null;
      }
      return value;
    } catch (_) {
      await delete(marketId);
      return null;
    }
  }

  @override
  Future<void> delete(String marketId) async {
    await _storage.delete(key: await _key(marketId));
  }
}
