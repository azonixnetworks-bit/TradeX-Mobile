import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/tradex_api_client.dart';

typedef CopyTradeJson = Map<String, dynamic>;

class CopyTradingRepository {
  CopyTradingRepository(this._apiClient, {CopyTradingIntentStore? intentStore})
    : _intentStore = intentStore ?? SecureCopyTradingIntentStore(_apiClient);

  final TradeXApiClient _apiClient;
  final CopyTradingIntentStore _intentStore;

  Future<CopyTradeJson> bootstrap() async =>
      _data(await _apiClient.getJson('/api/v1/copy-trade/bootstrap'));

  Future<List<CopyTradeJson>> brokers() async {
    final data = _data(await _apiClient.getJson('/api/v1/copy-trade/brokers'));
    return copyTradeList(data['brokers'] ?? data['broker_markets'] ?? data);
  }

  Future<CopyTradeJson> openBrokerAccount(CopyTradeJson broker) async {
    final marketId = broker['broker_market_uuid']?.toString();
    if (marketId == null || marketId.isEmpty) {
      throw StateError('Broker market identifier is unavailable.');
    }
    final data = _data(
      await _apiClient.postJson(
        '/api/v1/copy-trade/broker-markets/$marketId/open-account-action',
        const {},
      ),
    );
    await _intentStore.write(marketId, data);
    return data;
  }

  Future<CopyTradeJson?> pendingIntent(String marketId) =>
      _intentStore.read(marketId);

  Future<CopyTradeJson> submitBrokerAccount({
    required String marketId,
    required String accountNumber,
  }) async {
    final intent = await _intentStore.read(marketId);
    final intentUuid = intent?['onboarding_intent_uuid']?.toString();
    if (intentUuid == null || intentUuid.isEmpty) {
      throw StateError(
        'Open this broker through the TradeX partner action before submitting the account.',
      );
    }
    final data = _data(
      await _apiClient.postJson('/api/v1/copy-trade/broker-accounts', {
        'onboarding_intent_uuid': intentUuid,
        'account_number': accountNumber,
      }),
    );
    await _intentStore.delete(marketId);
    return _map(data['broker_account']);
  }

  Future<CopyTradeJson> resubmitBrokerAccount({
    required String accountId,
    required String accountNumber,
  }) async {
    final data = _data(
      await _apiClient.postJson(
        '/api/v1/copy-trade/broker-accounts/$accountId/resubmit',
        {'account_number': accountNumber},
      ),
    );
    return _map(data['broker_account']);
  }

  Future<CopyTradeJson> activation(String accountId) async {
    final data = _data(
      await _apiClient.getJson(
        '/api/v1/copy-trade/broker-accounts/$accountId/activation',
      ),
    );
    final activation = copyTradeMap(data['activation']);
    return activation.isEmpty ? data : activation;
  }

  Future<CopyTradeJson> billing() async =>
      _data(await _apiClient.getJson('/api/v1/copy-trade/billing'));

  Future<Uint8List> brokerLogo(String url) => _apiClient.getBytes(url);

  CopyTradeJson _data(CopyTradeJson response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }
}

abstract interface class CopyTradingIntentStore {
  Future<void> write(String marketId, CopyTradeJson value);
  Future<CopyTradeJson?> read(String marketId);
  Future<void> delete(String marketId);
}

class SecureCopyTradingIntentStore implements CopyTradingIntentStore {
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

CopyTradeJson copyTradeMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<CopyTradeJson> copyTradeList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const <CopyTradeJson>[];

CopyTradeJson _map(Object? value) => copyTradeMap(value);
