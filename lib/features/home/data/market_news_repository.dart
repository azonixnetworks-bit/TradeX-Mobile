import '../../../core/network/tradex_api_client.dart';

class MarketNewsRepository {
  const MarketNewsRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  Future<List<MarketNewsItem>> latest({int limit = 3}) async {
    final liveResponse = await _apiClient.getJson(
      '/api/v1/economic-news/live?per_page=$limit',
    );
    final liveData = liveResponse['data'];
    final rawUpdates = liveData is Map ? liveData['live_updates'] : null;
    final updates = rawUpdates is List
        ? rawUpdates
              .whereType<Map>()
              .map(
                (item) => MarketNewsItem.fromLiveUpdate(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.title.isNotEmpty)
              .take(limit)
              .toList(growable: false)
        : const <MarketNewsItem>[];
    if (updates.isNotEmpty) return updates;

    final from = Uri.encodeQueryComponent(
      DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 12))
          .toIso8601String(),
    );
    final eventResponse = await _apiClient.getJson(
      '/api/v1/economic-news/events?from=$from&per_page=$limit',
    );
    final eventData = eventResponse['data'];
    final rawEvents = eventData is Map ? eventData['events'] : null;
    if (rawEvents is! List) return const [];
    return rawEvents
        .whereType<Map>()
        .map(
          (item) => MarketNewsItem.fromEvent(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.title.isNotEmpty)
        .take(limit)
        .toList(growable: false);
  }
}

class MarketNewsItem {
  const MarketNewsItem({
    required this.uuid,
    required this.title,
    required this.summary,
    required this.currency,
    required this.impact,
    required this.occurredAt,
    required this.isLiveUpdate,
  });

  factory MarketNewsItem.fromLiveUpdate(Map<String, dynamic> json) {
    final message = _text(json['message']);
    return MarketNewsItem(
      uuid: _text(json['event_uuid'], fallback: _text(json['uuid'])),
      title: _text(json['event_title'], fallback: message),
      summary: message,
      currency: _firstPairSymbol(json['affected_pairs']),
      impact: _text(json['impact'], fallback: 'MARKET'),
      occurredAt: DateTime.tryParse(_text(json['published_at_utc'])),
      isLiveUpdate: true,
    );
  }

  factory MarketNewsItem.fromEvent(Map<String, dynamic> json) {
    final actual = _nullableText(json['actual']);
    final forecast = _nullableText(json['forecast']);
    final reason = _nullableText(json['reason']);
    final details = <String>[];
    if (actual != null) details.add('Actual $actual');
    if (forecast != null) details.add('Forecast $forecast');
    if (reason != null) details.add(reason);
    return MarketNewsItem(
      uuid: _text(json['uuid']),
      title: _text(json['title']),
      summary: details.isEmpty
          ? 'Scheduled market-moving economic event'
          : details.join(' • '),
      currency: _text(json['currency'], fallback: _text(json['country_code'])),
      impact: _text(json['impact'], fallback: 'MARKET'),
      occurredAt: DateTime.tryParse(_text(json['scheduled_at_utc'])),
      isLiveUpdate: false,
    );
  }

  final String uuid;
  final String title;
  final String summary;
  final String currency;
  final String impact;
  final DateTime? occurredAt;
  final bool isLiveUpdate;

  static String _firstPairSymbol(Object? value) {
    if (value is! List || value.isEmpty || value.first is! Map) return '';
    return _text((value.first as Map)['symbol']);
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
