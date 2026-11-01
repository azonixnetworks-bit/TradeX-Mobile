import 'dart:typed_data';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../domain/trade_ideas_repository.dart';
import '../../trade_ideas/domain/repositories/trade_idea_repository.dart';

class TradeIdeasRepository implements DashboardTradeIdeasRepository {
  TradeIdeasRepository(this._apiClient, this.detailsRepository);

  final TradeXApiClient _apiClient;
  TradeXApiClient get apiClient => _apiClient;
  @override
  final TradeIdeaRepositoryContract detailsRepository;

  @override
  Future<List<DashboardTradeIdea>> latestThree() => _latest(perPage: 12);

  @override
  Future<List<DashboardTradeIdea>> latestCrypto({int limit = 5}) =>
      _latest(perPage: limit.clamp(1, 20).toInt(), category: 'CRYPTO');

  Future<List<DashboardTradeIdea>> _latest({
    required int perPage,
    String? category,
  }) async {
    final categoryQuery = category == null
        ? ''
        : '&category=${Uri.encodeQueryComponent(category)}';
    final index = await _apiClient.getJson(
      '/api/v1/trade-ideas?per_page=$perPage$categoryQuery',
    );
    final data = index['data'];
    final ideas = data is Map ? data['trade_ideas'] : null;
    if (ideas is! List) return const [];

    return ideas
        .whereType<Map>()
        .map(
          (idea) =>
              DashboardTradeIdea.fromJson(Map<String, dynamic>.from(idea)),
        )
        .where((idea) => idea.uuid.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<Uint8List?> chartBytes(DashboardTradeIdea idea) async {
    if (!idea.chartAvailable) return null;
    try {
      return await _apiClient.getBytes(
        '/api/v1/trade-ideas/${idea.uuid}/chart',
      );
    } on ApiException {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> react(
    DashboardTradeIdea idea,
    String? reaction,
  ) async {
    final response = await _apiClient.putJson(
      '/api/v1/trade-ideas/${idea.uuid}/reaction',
      reaction == null ? const {} : {'reaction': reaction},
    );
    final data = response['data'];
    final summary = data is Map ? data['reaction'] : null;
    return summary is Map ? Map<String, dynamic>.from(summary) : const {};
  }
}
