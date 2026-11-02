import 'package:flutter/services.dart';

import '../../../core/domain/api_gateway.dart';
import '../domain/home_widget_publisher.dart';
import '../domain/market_news_repository.dart';
import '../domain/trade_ideas_repository.dart';

final class AndroidHomeWidgetPublisher implements HomeWidgetPublisher {
  AndroidHomeWidgetPublisher({
    required ApiGateway apiGateway,
    required MarketNewsRepositoryContract newsRepository,
    required DashboardTradeIdeasRepository tradeIdeasRepository,
  }) : this._(apiGateway, newsRepository, tradeIdeasRepository);

  AndroidHomeWidgetPublisher._(
    this._apiGateway,
    this._newsRepository,
    this._tradeIdeasRepository,
  );

  static const _channel = MethodChannel(
    'com.azonixnetworks.tradex_mobile/home_widget',
  );

  final ApiGateway _apiGateway;
  final MarketNewsRepositoryContract _newsRepository;
  final DashboardTradeIdeasRepository _tradeIdeasRepository;

  @override
  Future<void> refresh() async {
    final snapshot = <String, Object?>{};
    try {
      final response = await _apiGateway.getJson('/api/v1/market-clock');
      final data = response['data'];
      final sessions = data is Map ? data['sessions'] : null;
      if (sessions is List) {
        for (final raw in sessions.whereType<Map>()) {
          final name = raw['name']?.toString().trim() ?? '';
          if (name.isEmpty) continue;
          snapshot['session_${_sessionKey(name)}'] = raw['is_open'] == true
              ? 'OPEN'
              : 'CLOSED';
        }
      }
    } catch (_) {
      // Preserve the last launcher snapshot when the clock endpoint is offline.
    }
    try {
      final news = await _newsRepository.today();
      snapshot['news'] = news.isEmpty
          ? 'No major economic news scheduled today'
          : news.take(2).map((item) => item.title).join('  •  ');
    } catch (_) {
      // Preserve the last launcher news snapshot while offline.
    }
    try {
      final ideas = await _tradeIdeasRepository.latestThree();
      if (ideas.isNotEmpty) {
        final idea = ideas.first;
        snapshot['signal'] = [
          idea.symbol,
          idea.direction,
          idea.timeframe,
        ].where((part) => part.trim().isNotEmpty).join('  •  ');
      }
    } catch (_) {
      // Premium/session failures must not interrupt the dashboard.
    }
    if (snapshot.isEmpty) return;
    snapshot['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    try {
      await _channel.invokeMethod<void>('update', snapshot);
    } on MissingPluginException {
      // Android launcher widgets are unavailable on other platforms.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      // Android launcher widgets are unavailable on other platforms.
    }
  }

  String _sessionKey(String name) => name
      .toLowerCase()
      .replaceAll('new york', 'new_york')
      .replaceAll(RegExp(r'[^a-z_]'), '');
}
