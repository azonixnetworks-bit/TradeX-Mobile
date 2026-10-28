import '../../../../core/network/tradex_api_client.dart';
import '../models/support_models.dart';

abstract interface class SupportRemoteDataSource {
  Future<SupportJson> overview();
  Future<List<SupportJson>> categories();
  Future<SupportJson> startLiveChat({
    required String categoryUuid,
    required String idempotencyKey,
  });
  Future<SupportJson> chat(String chatUuid);
  Future<SupportJson> heartbeat(String chatUuid);
  Future<SupportJson> cancelChat(String chatUuid);
  Future<SupportJson> endChat(String chatUuid);
  Future<SupportJson> events(String chatUuid, {required int after});
  Future<SupportJson> sendMessage({
    required String ticketUuid,
    required String message,
    required String idempotencyKey,
  });
}

final class ApiSupportRemoteDataSource implements SupportRemoteDataSource {
  const ApiSupportRemoteDataSource(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<SupportJson> overview() async =>
      _data(await _apiClient.getJson('/api/v1/support/overview'));

  @override
  Future<List<SupportJson>> categories() async {
    final response = await _apiClient.getJson('/api/v1/support/categories');
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(supportMap).toList(growable: false);
  }

  @override
  Future<SupportJson> startLiveChat({
    required String categoryUuid,
    required String idempotencyKey,
  }) async => _data(
    await _apiClient.postJsonWithHeaders(
      '/api/v1/support/live-chat/start',
      {
        'category_uuid': categoryUuid,
        'subject': 'Mobile app live support request',
        'description': 'The customer started a secure live support conversation from the TradeX mobile app.',
        'requested_urgency': 'normal',
      },
      {'Idempotency-Key': idempotencyKey},
    ),
  );

  @override
  Future<SupportJson> chat(String chatUuid) async =>
      _data(await _apiClient.getJson('/api/v1/support/live-chat/$chatUuid'));

  @override
  Future<SupportJson> heartbeat(String chatUuid) async => _data(
    await _apiClient.postJson(
      '/api/v1/support/live-chat/$chatUuid/heartbeat',
      const {},
    ),
  );

  @override
  Future<SupportJson> cancelChat(String chatUuid) async => _data(
    await _apiClient.postJson(
      '/api/v1/support/live-chat/$chatUuid/cancel',
      const {},
    ),
  );

  @override
  Future<SupportJson> endChat(String chatUuid) async => _data(
    await _apiClient.postJson(
      '/api/v1/support/live-chat/$chatUuid/end',
      const {},
    ),
  );

  @override
  Future<SupportJson> events(String chatUuid, {required int after}) async =>
      _data(
        await _apiClient.getJson(
          '/api/v1/support/live-chat/$chatUuid/events?after=$after',
        ),
      );

  @override
  Future<SupportJson> sendMessage({
    required String ticketUuid,
    required String message,
    required String idempotencyKey,
  }) async => _data(
    await _apiClient.postJsonWithHeaders(
      '/api/v1/support/tickets/$ticketUuid/messages',
      {'message': message.trim()},
      {'Idempotency-Key': idempotencyKey},
    ),
  );

  static SupportJson _data(SupportJson response) {
    final value = response['data'];
    return value is Map ? supportMap(value) : response;
  }
}
