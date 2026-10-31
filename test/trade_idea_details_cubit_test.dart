import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/network/api_exception.dart';
import 'package:tradex_mobile/features/trade_ideas/data/trade_idea_repository.dart';
import 'package:tradex_mobile/features/trade_ideas/models/trade_idea_models.dart';
import 'package:tradex_mobile/features/trade_ideas/presentation/bloc/trade_idea_details_cubit.dart';
import 'package:tradex_mobile/features/trade_ideas/presentation/trade_idea_details_screen.dart';
import 'package:tradex_mobile/features/market/presentation/trading_view_chart_screen.dart';

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

  testWidgets('Open TradingView pushes the internal landscape chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: TradeIdeaDetailsScreen(
          repository: _NavigationSource(),
          uuid: uuid,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final buttonFinder = find.byKey(const ValueKey('open-tradingview-in-app'));
    expect(buttonFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(buttonFinder);
    expect(button.onPressed, isNotNull);

    observer.routes.clear();
    button.onPressed!();

    expect(observer.routes, hasLength(1));
    final route = observer.routes.single as MaterialPageRoute<void>;
    expect(route.settings.name, '/trade-ideas/tradingview');
    final destination = route.builder(tester.element(buttonFinder));
    expect(destination, isA<TradingViewChartScreen>());
    final chart = destination as TradingViewChartScreen;
    expect(chart.qualifiedSymbol, 'OANDA:XAUUSD');
    expect(chart.interval, '60');
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final routes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
    super.didPush(route, previousRoute);
  }
}

class _NavigationSource extends _FakeSource {
  @override
  Future<Uint8List> analysisChart(String uuid) {
    throw const ApiException(
      message: 'Analysis chart is unavailable.',
      statusCode: 404,
    );
  }
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
