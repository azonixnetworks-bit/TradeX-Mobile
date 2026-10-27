import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/trade_ideas/data/trade_idea_repository.dart';
import 'package:tradex_mobile/features/trade_ideas/models/trade_idea_models.dart';
import 'package:tradex_mobile/features/trade_ideas/presentation/bloc/trade_idea_details_cubit.dart';

void main() {
  const uuid = '123e4567-e89b-42d3-a456-426614174000';

  test('loads detail and protected analysis bytes lazily', () async {
    final source = _FakeSource();
    final cubit = TradeIdeaDetailsCubit(repository: source, uuid: uuid);

    await cubit.load();

    expect(cubit.state.status, TradeIdeaLoadStatus.ready);
    expect(cubit.state.analysisStatus, TradeIdeaAnalysisStatus.loaded);
    expect(cubit.state.analysisBytes, Uint8List.fromList([1, 2, 3]));
    expect(source.chartCalls, 1);
    await cubit.close();
  });

  test('rolls optimistic reaction back when API rejects it', () async {
    final source = _FakeSource(failReaction: true);
    final cubit = TradeIdeaDetailsCubit(repository: source, uuid: uuid);
    await cubit.load();

    await cubit.react('LIKE');

    expect(cubit.state.detail!.summary.reactions.likes, 2);
    expect(cubit.state.detail!.summary.reactions.viewerReaction, isNull);
    expect(cubit.state.reactionMessage, isNotNull);
    await cubit.close();
  });
}

class _FakeSource implements TradeIdeaDataSource {
  _FakeSource({this.failReaction = false});
  final bool failReaction;
  int chartCalls = 0;

  @override
  Future<Uint8List> analysisChart(String uuid) async {
    chartCalls++;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<TradeIdeaDetail> detail(String uuid) async =>
      TradeIdeaDetail.fromJson({
        'uuid': uuid,
        'symbol': 'XAUUSD',
        'category': 'FOREX',
        'direction': 'BUY',
        'timeframe': 'H1',
        'chart_available': true,
        'targets': [
          {'label': 'TP1', 'price': '2428', 'is_hit': false},
        ],
        'reactions': {'likes_count': 2, 'dislikes_count': 0},
      });

  @override
  Future<TradeIdeaPage> list({
    int page = 1,
    int perPage = 10,
    String? category,
    String? symbol,
  }) => throw UnimplementedError();

  @override
  Future<TradeIdeaReactionSummary> react(String uuid, String? reaction) async {
    if (failReaction) throw Exception('offline');
    return TradeIdeaReactionSummary(
      likes: 3,
      dislikes: 0,
      viewerReaction: reaction,
    );
  }

  @override
  Future<TradeIdeaShareAction> shareAction(
    String uuid, {
    required String channel,
    String variant = 'portrait',
  }) => throw UnimplementedError();
}
