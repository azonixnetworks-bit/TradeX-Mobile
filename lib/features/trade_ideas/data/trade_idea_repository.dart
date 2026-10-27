import 'dart:typed_data';

import '../../../core/network/tradex_api_client.dart';
import '../models/trade_idea_models.dart';

abstract interface class TradeIdeaDataSource {
  Future<TradeIdeaPage> list({
    int page = 1,
    int perPage = 10,
    String? category,
    String? symbol,
  });
  Future<TradeIdeaDetail> detail(String uuid);
  Future<Uint8List> analysisChart(String uuid);
  Future<TradeIdeaReactionSummary> react(String uuid, String? reaction);
  Future<TradeIdeaShareAction> shareAction(
    String uuid, {
    required String channel,
    String variant = 'portrait',
  });
}

class TradeIdeaRepository implements TradeIdeaDataSource {
  const TradeIdeaRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<TradeIdeaPage> list({
    int page = 1,
    int perPage = 10,
    String? category,
    String? symbol,
  }) async {
    final parameters = <String, String>{
      'page': '${page < 1 ? 1 : page}',
      'per_page': '${perPage.clamp(1, 50)}',
    };
    final normalizedCategory = category?.trim().toUpperCase() ?? '';
    final normalizedSymbol = symbol?.trim().toUpperCase() ?? '';
    if (normalizedCategory.isNotEmpty && normalizedCategory != 'ALL') {
      parameters['category'] = normalizedCategory;
    }
    if (normalizedSymbol.isNotEmpty) parameters['symbol'] = normalizedSymbol;
    final query = parameters.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final response = await _apiClient.getJson('/api/v1/trade-ideas?$query');
    final data = tradeIdeaMap(response['data']);
    final meta = tradeIdeaMap(response['meta']);
    return TradeIdeaPage(
      items: tradeIdeaList(data['trade_ideas'])
          .map(TradeIdeaSummary.fromJson)
          .where((idea) => idea.uuid.isNotEmpty)
          .toList(growable: false),
      currentPage: tradeIdeaInt(meta['current_page']).clamp(1, 1 << 30).toInt(),
      lastPage: tradeIdeaInt(meta['last_page']).clamp(1, 1 << 30).toInt(),
      total: tradeIdeaInt(meta['total']),
    );
  }

  @override
  Future<TradeIdeaDetail> detail(String uuid) async {
    _assertUuid(uuid);
    final response = await _apiClient.getJson(
      '/api/v1/trade-ideas/${Uri.encodeComponent(uuid)}',
    );
    final idea = tradeIdeaMap(tradeIdeaMap(response['data'])['trade_idea']);
    if (idea.isEmpty) {
      throw const FormatException('Trade Idea details are unavailable.');
    }
    return TradeIdeaDetail.fromJson(idea);
  }

  @override
  Future<Uint8List> analysisChart(String uuid) {
    _assertUuid(uuid);
    return _apiClient.getBytes(
      '/api/v1/trade-ideas/${Uri.encodeComponent(uuid)}/chart',
    );
  }

  @override
  Future<TradeIdeaReactionSummary> react(String uuid, String? reaction) async {
    _assertUuid(uuid);
    final response = await _apiClient.putJson(
      '/api/v1/trade-ideas/${Uri.encodeComponent(uuid)}/reaction',
      reaction == null ? const {} : {'reaction': reaction},
    );
    return TradeIdeaReactionSummary.fromJson(
      tradeIdeaMap(tradeIdeaMap(response['data'])['reaction']),
    );
  }

  @override
  Future<TradeIdeaShareAction> shareAction(
    String uuid, {
    required String channel,
    String variant = 'portrait',
  }) async {
    _assertUuid(uuid);
    final response = await _apiClient.postJson(
      '/api/v1/trade-ideas/${Uri.encodeComponent(uuid)}/share-action',
      {'channel': channel.toUpperCase(), 'variant': variant.toLowerCase()},
    );
    final action = tradeIdeaMap(tradeIdeaMap(response['data'])['share_action']);
    return TradeIdeaShareAction(
      externalUrl: tradeIdeaText(action['external_share_url']),
      message: tradeIdeaText(action['message']),
    );
  }

  void _assertUuid(String uuid) {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(uuid.trim())) {
      throw const FormatException('Trade Idea identifier is invalid.');
    }
  }
}

class TradeIdeaShareAction {
  const TradeIdeaShareAction({
    required this.externalUrl,
    required this.message,
  });

  final String externalUrl;
  final String message;
}
