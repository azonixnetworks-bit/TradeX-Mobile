import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/tradex_api_client.dart';

class MarketNewsRepository {
  const MarketNewsRepository(this._apiClient);

  static const _dailyCacheKey = 'tradex.economic_news.upcoming.v2';
  static final Map<String, Future<List<MarketNewsItem>>> _inFlightByDay = {};

  final TradeXApiClient _apiClient;

  Future<List<MarketNewsItem>> latest({int limit = 4}) async {
    final events = await today();
    return events.take(limit).toList(growable: false);
  }

  Future<List<MarketNewsItem>> today({DateTime? now}) async {
    final localNow = now ?? DateTime.now();
    final day = _dayKey(localNow);
    final preferences = await SharedPreferences.getInstance();
    final cached = _readCache(preferences.getString(_dailyCacheKey));
    if (cached?.day == day) {
      return _parseUpcomingEvents(cached!.events, localNow);
    }

    final existing = _inFlightByDay[day];
    if (existing != null) return existing;

    final request = _fetchAndCache(
      preferences: preferences,
      day: day,
      localNow: localNow,
      stale: cached,
    );
    _inFlightByDay[day] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlightByDay[day], request)) {
        _inFlightByDay.remove(day);
      }
    }
  }

  Future<List<MarketNewsItem>> _fetchAndCache({
    required SharedPreferences preferences,
    required String day,
    required DateTime localNow,
    required _MarketNewsCache? stale,
  }) async {
    final from = Uri.encodeQueryComponent(localNow.toUtc().toIso8601String());
    final to = Uri.encodeQueryComponent(
      localNow.add(const Duration(days: 14)).toUtc().toIso8601String(),
    );

    try {
      final response = await _apiClient.getJson(
        '/api/v1/economic-news/calendar?from=$from&to=$to&per_page=100',
      );
      final data = response['data'];
      final rawEvents = data is Map ? data['events'] : null;
      final events = rawEvents is List
          ? rawEvents
                .whereType<Map>()
                .map((event) => Map<String, dynamic>.from(event))
                .toList(growable: false)
          : <Map<String, dynamic>>[];
      await preferences.setString(
        _dailyCacheKey,
        jsonEncode(<String, dynamic>{
          'day': day,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
          'events': events,
        }),
      );
      return _parseUpcomingEvents(events, localNow);
    } catch (_) {
      if (stale != null) return _parseUpcomingEvents(stale.events, localNow);
      rethrow;
    }
  }

  static List<MarketNewsItem> _parseUpcomingEvents(
    List<Map<String, dynamic>> events,
    DateTime reference,
  ) {
    final parsed = events
        .map(MarketNewsItem.fromEvent)
        .where((item) => item.title.isNotEmpty)
        .where((item) {
          final status = item.status.toUpperCase();
          if (status == 'CANCELLED') return false;
          if (status == 'LIVE') return true;
          final scheduled = item.occurredAt;
          return scheduled == null || !scheduled.isBefore(reference);
        })
        .toList(growable: false);
    parsed.sort((a, b) {
      final left = a.occurredAt;
      final right = b.occurredAt;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return parsed;
  }

  static _MarketNewsCache? _readCache(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['events'] is! List) return null;
      return _MarketNewsCache(
        day: decoded['day']?.toString() ?? '',
        events: (decoded['events'] as List)
            .whereType<Map>()
            .map((event) => Map<String, dynamic>.from(event))
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class MarketNewsItem {
  const MarketNewsItem({
    required this.uuid,
    required this.title,
    required this.summary,
    required this.currency,
    required this.impact,
    required this.bias,
    required this.confidenceScore,
    required this.source,
    required this.affectedPairs,
    required this.status,
    required this.occurredAt,
    required this.isLiveUpdate,
  });

  factory MarketNewsItem.fromLiveUpdate(Map<String, dynamic> json) {
    final message = _text(json['message']);
    final pairs = _pairSymbols(json['affected_pairs']);
    return MarketNewsItem(
      uuid: _text(json['event_uuid'], fallback: _text(json['uuid'])),
      title: _text(json['event_title'], fallback: message),
      summary: message,
      currency: pairs.isEmpty ? '' : pairs.first,
      impact: _text(json['impact'], fallback: 'LOW'),
      bias: _text(json['bias'], fallback: 'NEUTRAL'),
      confidenceScore: _score(json['confidence_score']),
      source: _source(json['source']),
      affectedPairs: pairs,
      status: 'LIVE',
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
    final pairs = _pairSymbols(json['affected_pairs']);
    return MarketNewsItem(
      uuid: _text(json['uuid']),
      title: _text(json['title']),
      summary: details.isEmpty
          ? 'Scheduled market-moving economic event'
          : details.join(' • '),
      currency: _text(
        json['currency'],
        fallback: pairs.isEmpty ? _text(json['country_code']) : pairs.first,
      ),
      impact: _text(json['impact'], fallback: 'LOW'),
      bias: _text(json['bias'], fallback: 'NEUTRAL'),
      confidenceScore: _score(json['confidence_score']),
      source: _source(json['source']),
      affectedPairs: pairs,
      status: _text(json['status'], fallback: 'SCHEDULED'),
      occurredAt: DateTime.tryParse(_text(json['scheduled_at_utc'])),
      isLiveUpdate: false,
    );
  }

  final String uuid;
  final String title;
  final String summary;
  final String currency;
  final String impact;
  final String bias;
  final int confidenceScore;
  final String source;
  final List<String> affectedPairs;
  final String status;
  final DateTime? occurredAt;
  final bool isLiveUpdate;

  static List<String> _pairSymbols(Object? value) {
    if (value is! List) return const [];
    final symbols = <String>[];
    for (final pair in value.whereType<Map>()) {
      final symbol = _text(pair['symbol']);
      if (symbol.isNotEmpty && !symbols.contains(symbol)) symbols.add(symbol);
    }
    return List.unmodifiable(symbols);
  }

  static String _source(Object? value) {
    if (value is! Map) return 'TradeX Economic Calendar';
    return _text(
      value['name'],
      fallback: _text(value['code'], fallback: 'TradeX'),
    );
  }

  static int _score(Object? value) {
    if (value is num) return value.round().clamp(0, 100);
    return (int.tryParse(value?.toString() ?? '') ?? 0).clamp(0, 100);
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

class _MarketNewsCache {
  const _MarketNewsCache({required this.day, required this.events});

  final String day;
  final List<Map<String, dynamic>> events;
}
