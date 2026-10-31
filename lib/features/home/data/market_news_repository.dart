import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/tradex_api_client.dart';
import '../domain/no_trade_zone_warning.dart';

class MarketNewsRepository {
  const MarketNewsRepository(this._apiClient);

  static const _dailyCacheKey = 'tradex.economic_news.upcoming.v4';
  static const _cacheFreshFor = Duration(minutes: 5);
  static final Map<String, Future<List<MarketNewsItem>>> _inFlightByDay = {};

  final TradeXApiClient _apiClient;

  Future<List<MarketNewsItem>> latest({
    int limit = 4,
    bool forceRefresh = false,
  }) async {
    final events = await today(forceRefresh: forceRefresh);
    return events.take(limit).toList(growable: false);
  }

  Future<List<MarketNewsItem>> today({
    DateTime? now,
    bool forceRefresh = false,
  }) async {
    final localNow = now ?? DateTime.now();
    final day = _dayKey(localNow);
    final preferences = await SharedPreferences.getInstance();
    final cached = _readCache(preferences.getString(_dailyCacheKey));
    if (!forceRefresh &&
        cached?.day == day &&
        cached!.events.isNotEmpty &&
        DateTime.now().toUtc().difference(cached.savedAt) < _cacheFreshFor) {
      return _parseUpcomingEvents(cached.events, localNow, cached.savedAt);
    }

    final requestKey = forceRefresh ? '$day:refresh' : day;
    final existing = _inFlightByDay[requestKey];
    if (existing != null) return existing;

    final request = _fetchAndCache(
      preferences: preferences,
      day: day,
      localNow: localNow,
      stale: cached,
    );
    _inFlightByDay[requestKey] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlightByDay[requestKey], request)) {
        _inFlightByDay.remove(requestKey);
      }
    }
  }

  Future<List<MarketNewsItem>> _fetchAndCache({
    required SharedPreferences preferences,
    required String day,
    required DateTime localNow,
    required _MarketNewsCache? stale,
  }) async {
    final from = Uri.encodeQueryComponent(
      localNow.subtract(const Duration(minutes: 35)).toUtc().toIso8601String(),
    );
    final to = Uri.encodeQueryComponent(
      localNow.add(const Duration(days: 14)).toUtc().toIso8601String(),
    );

    try {
      var events = <Map<String, dynamic>>[];
      Object? lastError;
      StackTrace? lastStackTrace;
      var receivedResponse = false;
      for (final endpoint in const ['events', 'calendar']) {
        try {
          final response = await _apiClient.getJson(
            '/api/v1/economic-news/$endpoint?from=$from&to=$to&per_page=100',
          );
          receivedResponse = true;
          events = _eventMaps(response);
          if (events.isNotEmpty) break;
        } catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
        }
      }
      if (!receivedResponse && lastError != null) {
        Error.throwWithStackTrace(lastError, lastStackTrace!);
      }
      final savedAt = DateTime.now().toUtc();
      await preferences.setString(
        _dailyCacheKey,
        jsonEncode(<String, dynamic>{
          'day': day,
          'saved_at': savedAt.toIso8601String(),
          'events': events,
        }),
      );
      return _parseUpcomingEvents(events, localNow, savedAt);
    } catch (_) {
      if (stale != null) {
        return _parseUpcomingEvents(stale.events, localNow, stale.savedAt);
      }
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _eventMaps(Map<String, dynamic> response) {
    Object? payload = response['data'];
    if (payload is Map) {
      payload = payload['events'] ?? payload['items'] ?? payload['data'];
    }
    payload ??= response['events'] ?? response['items'];
    if (payload is Map) payload = payload['data'];
    if (payload is! List) return const [];
    return payload
        .whereType<Map>()
        .map((event) => Map<String, dynamic>.from(event))
        .toList(growable: false);
  }

  static List<MarketNewsItem> _parseUpcomingEvents(
    List<Map<String, dynamic>> events,
    DateTime reference,
    DateTime observedAt,
  ) {
    final parsed = events
        .map((event) => MarketNewsItem.fromEvent(event, observedAt: observedAt))
        .where((item) => item.title.isNotEmpty)
        .where((item) {
          final status = item.status.toUpperCase();
          if (status == 'CANCELLED') return false;
          if (status == 'LIVE') return true;
          final scheduled = item.occurredAt;
          return scheduled == null ||
              !scheduled.add(const Duration(minutes: 35)).isBefore(reference);
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
        savedAt:
            DateTime.tryParse(decoded['saved_at']?.toString() ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
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
    required this.category,
    required this.previous,
    required this.forecast,
    required this.actual,
    required this.countryCode,
    required this.currency,
    required this.impact,
    required this.bias,
    required this.confidenceScore,
    required this.source,
    required this.affectedPairs,
    required this.status,
    required this.occurredAt,
    required this.isLiveUpdate,
    required this.observedAtUtc,
  });

  factory MarketNewsItem.fromLiveUpdate(Map<String, dynamic> json) {
    final message = _text(json['message']);
    final pairs = _pairSymbols(json['affected_pairs']);
    return MarketNewsItem(
      uuid: _text(json['event_uuid'], fallback: _text(json['uuid'])),
      title: _text(json['event_title'], fallback: message),
      summary: message,
      category: _text(json['category']),
      previous: _nullableText(json['previous']),
      forecast: _nullableText(json['forecast']),
      actual: _nullableText(json['actual']),
      countryCode: _text(json['country_code']),
      currency: pairs.isEmpty ? '' : pairs.first,
      impact: _text(json['impact'], fallback: 'LOW'),
      bias: _text(json['bias'], fallback: 'NEUTRAL'),
      confidenceScore: _score(json['confidence_score']),
      source: _source(json['source']),
      affectedPairs: pairs,
      status: 'LIVE',
      occurredAt: DateTime.tryParse(_text(json['published_at_utc'])),
      isLiveUpdate: true,
      observedAtUtc: DateTime.now().toUtc(),
    );
  }

  factory MarketNewsItem.fromEvent(
    Map<String, dynamic> json, {
    DateTime? observedAt,
  }) {
    final actual = _nullableText(json['actual']);
    final forecast = _nullableText(json['forecast']);
    final previous =
        _nullableText(json['revised_previous']) ??
        _nullableText(json['previous']);
    final reason = _nullableText(json['reason']);
    final details = <String>[];
    if (actual != null) details.add('Actual $actual');
    if (forecast != null) details.add('Forecast $forecast');
    if (previous != null) details.add('Previous $previous');
    if (reason != null) details.add(reason);
    final pairs = _pairSymbols(json['affected_pairs']);
    return MarketNewsItem(
      uuid: _text(json['uuid']),
      title: _text(json['title']),
      summary: details.isEmpty
          ? 'Scheduled market-moving economic event'
          : details.join(' • '),
      category: _text(json['category']),
      previous: previous,
      forecast: forecast,
      actual: actual,
      countryCode: _text(json['country_code']),
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
      observedAtUtc: (observedAt ?? DateTime.now()).toUtc(),
    );
  }

  final String uuid;
  final String title;
  final String summary;
  final String category;
  final String? previous;
  final String? forecast;
  final String? actual;
  final String countryCode;
  final String currency;
  final String impact;
  final String bias;
  final int confidenceScore;
  final String source;
  final List<String> affectedPairs;
  final String status;
  final DateTime? occurredAt;
  final bool isLiveUpdate;
  final DateTime observedAtUtc;

  EconomicNewsSnapshot toWarningSnapshot() => EconomicNewsSnapshot(
    uuid: uuid,
    title: title,
    currency: currency,
    impact: impact,
    status: status,
    scheduledAtUtc: occurredAt?.toUtc(),
    affectedPairs: affectedPairs,
    observedAtUtc: observedAtUtc,
  );

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
  const _MarketNewsCache({
    required this.day,
    required this.savedAt,
    required this.events,
  });

  final String day;
  final DateTime savedAt;
  final List<Map<String, dynamic>> events;
}
