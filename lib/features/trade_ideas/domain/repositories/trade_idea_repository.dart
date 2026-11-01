import 'dart:typed_data';

import '../entities/trade_idea_entities.dart';

abstract interface class TradeIdeaRepositoryContract {
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

abstract interface class TradeIdeaDataSource
    implements TradeIdeaRepositoryContract {}

class TradeIdeaShareAction {
  const TradeIdeaShareAction({
    required this.externalUrl,
    required this.message,
  });
  final String externalUrl;
  final String message;
}
