import 'package:flutter/foundation.dart';

@immutable
class TradeJournalEntry {
  const TradeJournalEntry({
    required this.uuid,
    required this.market,
    required this.stockRegion,
    required this.symbol,
    required this.direction,
    required this.status,
    required this.tradeAt,
    required this.sessionLabel,
    required this.sessionSource,
    required this.broker,
    required this.accountLabel,
    required this.setupStrategy,
    required this.timeframes,
    required this.entryReason,
    required this.notesBefore,
    required this.prices,
    required this.risk,
    required this.psychologyBefore,
    required this.checklist,
    required this.executionNote,
    required this.openedAt,
    required this.exitAt,
    required this.result,
    required this.pnl,
    required this.review,
    required this.screenshots,
    required this.actions,
    required this.raw,
  });

  factory TradeJournalEntry.fromJson(Map<String, dynamic> json) {
    return TradeJournalEntry(
      uuid: _text(json['uuid']),
      market: _text(json['market']),
      stockRegion: _nullableText(json['stock_region']),
      symbol: _text(json['symbol']),
      direction: _text(json['direction']),
      status: _text(json['status']),
      tradeAt: DateTime.tryParse(_text(json['trade_at_local'])),
      sessionLabel: _text(_map(json['session'])['label']),
      sessionSource: _text(_map(json['session'])['source']),
      broker: _nullableText(json['broker']),
      accountLabel: _nullableText(json['account_label']),
      setupStrategy: _nullableText(json['setup_strategy']),
      timeframes: _strings(json['timeframes']),
      entryReason: _text(json['entry_reason']),
      notesBefore: _nullableText(json['notes_before']),
      prices: _map(json['prices']),
      risk: _map(json['risk']),
      psychologyBefore: _map(json['psychology_before']),
      checklist: _map(json['checklist']),
      executionNote: _nullableText(json['execution_note']),
      openedAt: DateTime.tryParse(_text(json['opened_at'])),
      exitAt: DateTime.tryParse(_text(json['exit_at'])),
      result: _nullableText(json['result']),
      pnl: _map(json['pnl']),
      review: _map(json['review']),
      screenshots: _map(json['screenshots']),
      actions: _map(json['actions']),
      raw: Map.unmodifiable(json),
    );
  }

  final String uuid;
  final String market;
  final String? stockRegion;
  final String symbol;
  final String direction;
  final String status;
  final DateTime? tradeAt;
  final String sessionLabel;
  final String sessionSource;
  final String? broker;
  final String? accountLabel;
  final String? setupStrategy;
  final List<String> timeframes;
  final String entryReason;
  final String? notesBefore;
  final Map<String, dynamic> prices;
  final Map<String, dynamic> risk;
  final Map<String, dynamic> psychologyBefore;
  final Map<String, dynamic> checklist;
  final String? executionNote;
  final DateTime? openedAt;
  final DateTime? exitAt;
  final String? result;
  final Map<String, dynamic> pnl;
  final Map<String, dynamic> review;
  final Map<String, dynamic> screenshots;
  final Map<String, dynamic> actions;
  final Map<String, dynamic> raw;

  bool get canEdit => actions['can_edit'] == true;
  bool get canOpen => actions['can_open'] == true;
  bool get canClose => actions['can_close'] == true;
  bool get canCancel => actions['can_cancel'] == true;
  bool get beforeScreenshotAvailable => screenshots['before_available'] == true;
  bool get afterScreenshotAvailable => screenshots['after_available'] == true;
  double? get netPnl => journalNumber(pnl['net']);
  String? get pnlCurrency => _nullableText(pnl['currency']);
  double? get plannedRr => journalNumber(risk['planned_rr']);
  double? get realizedR => journalNumber(risk['realized_r']);
}

@immutable
class TradeJournalHome {
  const TradeJournalHome({
    required this.timezone,
    required this.today,
    required this.week,
    required this.month,
    required this.recent,
  });

  factory TradeJournalHome.fromJson(Map<String, dynamic> json) =>
      TradeJournalHome(
        timezone: _text(json['timezone']),
        today: _map(json['today']),
        week: _map(json['week']),
        month: _map(json['month']),
        recent: _maps(json['recent'])
            .map(TradeJournalEntry.fromJson)
            .toList(growable: false),
      );

  final String timezone;
  final Map<String, dynamic> today;
  final Map<String, dynamic> week;
  final Map<String, dynamic> month;
  final List<TradeJournalEntry> recent;
}

@immutable
class TradeJournalPage {
  const TradeJournalPage({
    required this.entries,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory TradeJournalPage.fromJson(Map<String, dynamic> json) =>
      TradeJournalPage(
        entries: _maps(json['data'])
            .map(TradeJournalEntry.fromJson)
            .toList(growable: false),
        currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  final List<TradeJournalEntry> entries;
  final int currentPage;
  final int lastPage;
  final int total;
}

@immutable
class TradeJournalSymbolSuggestion {
  const TradeJournalSymbolSuggestion({
    required this.symbol,
    required this.name,
    this.logoUrl,
    this.price,
  });

  factory TradeJournalSymbolSuggestion.fromJson(Map<String, dynamic> json) =>
      TradeJournalSymbolSuggestion(
        symbol: _text(json['symbol']).toUpperCase(),
        name: _text(json['name']),
        logoUrl: _nullableText(json['logo_url']),
        price: journalNumber(
          json['price'] ??
              json['last_price'] ??
              json['current_price'] ??
              json['close'],
        ),
      );

  final String symbol;
  final String name;
  final String? logoUrl;
  final double? price;
}

@immutable
class TradeJournalMeta {
  const TradeJournalMeta({
    required this.markets,
    required this.stockRegions,
    required this.directions,
    required this.statuses,
    required this.results,
    required this.timeframes,
    required this.emotionsBefore,
    required this.emotionsAfter,
    required this.followedPlanAfter,
    required this.mistakeTags,
  });

  factory TradeJournalMeta.fromJson(Map<String, dynamic> json) =>
      TradeJournalMeta(
        markets: _strings(json['markets']),
        stockRegions: _strings(json['stock_regions']),
        directions: _strings(json['directions']),
        statuses: _strings(json['statuses']),
        results: _strings(json['results']),
        timeframes: _strings(json['timeframes']),
        emotionsBefore: _strings(json['emotions_before']),
        emotionsAfter: _strings(json['emotions_after']),
        followedPlanAfter: _strings(json['followed_plan_after']),
        mistakeTags: _strings(json['mistake_tags']),
      );

  final List<String> markets;
  final List<String> stockRegions;
  final List<String> directions;
  final List<String> statuses;
  final List<String> results;
  final List<String> timeframes;
  final List<String> emotionsBefore;
  final List<String> emotionsAfter;
  final List<String> followedPlanAfter;
  final List<String> mistakeTags;
}

Map<String, dynamic> journalData(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : response;
}

Map<String, dynamic> journalMap(Object? value) => _map(value);

List<Map<String, dynamic>> journalMaps(Object? value) => _maps(value);

List<String> journalStrings(Object? value) => _strings(value);

double? journalNumber(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String journalText(Object? value) => _text(value);

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false)
    : const <Map<String, dynamic>>[];

List<String> _strings(Object? value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const <String>[];

String _text(Object? value) => value?.toString() ?? '';

String? _nullableText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
