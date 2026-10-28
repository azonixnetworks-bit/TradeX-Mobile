import 'dart:typed_data';

import '../../../../core/network/tradex_api_client.dart';
import '../models/copy_trading_models.dart';

abstract interface class CopyTradingRemoteDataSource {
  Future<CopyTradeJson> bootstrap();
  Future<List<CopyTradeJson>> brokers();
  Future<CopyTradeJson> openBrokerAccount(String marketId);
  Future<CopyTradeJson> submitBrokerAccount({
    required String intentUuid,
    required String accountNumber,
  });
  Future<CopyTradeJson> resubmitBrokerAccount({
    required String accountId,
    required String accountNumber,
  });
  Future<CopyTradeJson> activation(String accountId);
  Future<Uint8List> brokerLogo(String url);
}

final class ApiCopyTradingRemoteDataSource
    implements CopyTradingRemoteDataSource {
  const ApiCopyTradingRemoteDataSource(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<CopyTradeJson> bootstrap() async =>
      _data(await _apiClient.getJson('/api/v1/copy-trade/bootstrap'));

  @override
  Future<List<CopyTradeJson>> brokers() async {
    final data = _data(await _apiClient.getJson('/api/v1/copy-trade/brokers'));
    return copyTradeList(data['brokers'] ?? data['broker_markets'] ?? data);
  }

  @override
  Future<CopyTradeJson> openBrokerAccount(String marketId) async => _data(
    await _apiClient.postJson(
      '/api/v1/copy-trade/broker-markets/$marketId/open-account-action',
      const {},
    ),
  );

  @override
  Future<CopyTradeJson> submitBrokerAccount({
    required String intentUuid,
    required String accountNumber,
  }) async {
    final data = _data(
      await _apiClient.postJson('/api/v1/copy-trade/broker-accounts', {
        'onboarding_intent_uuid': intentUuid,
        'account_number': accountNumber,
      }),
    );
    return copyTradeMap(data['broker_account']);
  }

  @override
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
    return copyTradeMap(data['broker_account']);
  }

  @override
  Future<CopyTradeJson> activation(String accountId) async {
    final data = _data(
      await _apiClient.getJson(
        '/api/v1/copy-trade/broker-accounts/$accountId/activation',
      ),
    );
    final activation = copyTradeMap(data['activation']);
    return activation.isEmpty ? data : activation;
  }

  @override
  Future<Uint8List> brokerLogo(String url) => _apiClient.getBytes(url);

  static CopyTradeJson _data(CopyTradeJson response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }
}
