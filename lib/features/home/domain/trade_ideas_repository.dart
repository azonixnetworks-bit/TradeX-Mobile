import 'dart:typed_data';

import '../../trade_ideas/domain/repositories/trade_idea_repository.dart';

abstract interface class DashboardTradeIdeasRepository {
  TradeIdeaRepositoryContract get detailsRepository;
  Future<List<DashboardTradeIdea>> latestThree();
  Future<List<DashboardTradeIdea>> latestCrypto({int limit = 5});
  Future<Uint8List?> chartBytes(DashboardTradeIdea idea);
  Future<Map<String, dynamic>> react(DashboardTradeIdea idea, String? reaction);
}

class DashboardTradeIdea {
  DashboardTradeIdea({
    required this.uuid,
    required this.category,
    required this.symbol,
    required this.instrumentName,
    required this.direction,
    required this.timeframe,
    required this.entry,
    required this.stopLoss,
    required this.targets,
    required this.chartAvailable,
    required this.tradingViewUrl,
    required this.latestUpdate,
    required this.likesCount,
    required this.dislikesCount,
    required this.viewerReaction,
  });

  factory DashboardTradeIdea.fromJson(Map<String, dynamic> json) {
    final entry = json['entry'];
    final stopLoss = json['stop_loss'];
    final timeline = json['timeline'];
    final targets = json['targets'];
    final reactions = json['reactions'];
    return DashboardTradeIdea(
      uuid: json['uuid']?.toString() ?? '',
      category: json['category']?.toString().toUpperCase() ?? '',
      symbol: json['symbol']?.toString() ?? 'MARKET',
      instrumentName: json['instrument_name']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '—',
      timeframe: json['timeframe']?.toString() ?? '—',
      entry: _rangeText(entry),
      stopLoss: _valueText(stopLoss is Map ? stopLoss['current'] : null),
      targets: targets is List
          ? targets
                .whereType<Map>()
                .map(
                  (target) => DashboardTradeTarget.fromJson(
                    Map<String, dynamic>.from(target),
                  ),
                )
                .toList(growable: false)
          : targets is Map && ((targets['total'] as num?)?.toInt() ?? 0) > 0
          ? [
              DashboardTradeTarget(
                label: 'Targets',
                price:
                    '${(targets['hit'] as num?)?.toInt() ?? 0}/${(targets['total'] as num?)?.toInt() ?? 0}',
              ),
            ]
          : const [],
      chartAvailable: json['chart_available'] == true,
      tradingViewUrl: json['tradingview_url']?.toString(),
      latestUpdate:
          timeline is List && timeline.isNotEmpty && timeline.first is Map
          ? TradeIdeaUpdate.fromJson(
              Map<String, dynamic>.from(timeline.first as Map),
            )
          : null,
      likesCount: reactions is Map
          ? (reactions['likes_count'] as num?)?.toInt() ?? 0
          : 0,
      dislikesCount: reactions is Map
          ? (reactions['dislikes_count'] as num?)?.toInt() ?? 0
          : 0,
      viewerReaction: reactions is Map
          ? reactions['viewer_reaction']?.toString()
          : null,
    );
  }

  final String uuid;
  final String category;
  final String symbol;
  final String instrumentName;
  final String direction;
  final String timeframe;
  final String entry;
  final String stopLoss;
  final List<DashboardTradeTarget> targets;
  final bool chartAvailable;
  final String? tradingViewUrl;
  final TradeIdeaUpdate? latestUpdate;
  int likesCount;
  int dislikesCount;
  String? viewerReaction;

  void applyReaction(String? next) {
    if (viewerReaction == next) return;
    if (viewerReaction == 'LIKE') likesCount--;
    if (viewerReaction == 'DISLIKE') dislikesCount--;
    if (next == 'LIKE') likesCount++;
    if (next == 'DISLIKE') dislikesCount++;
    viewerReaction = next;
  }

  void applyReactionSummary(Map<String, dynamic> json) {
    likesCount = (json['likes_count'] as num?)?.toInt() ?? likesCount;
    dislikesCount = (json['dislikes_count'] as num?)?.toInt() ?? dislikesCount;
    viewerReaction = json['viewer_reaction']?.toString();
  }
}

class DashboardTradeTarget {
  const DashboardTradeTarget({required this.label, required this.price});

  factory DashboardTradeTarget.fromJson(Map<String, dynamic> json) {
    return DashboardTradeTarget(
      label: json['label']?.toString().trim().isNotEmpty == true
          ? json['label'].toString()
          : 'TP',
      price: _valueText(json['price']),
    );
  }

  final String label;
  final String price;
}

class TradeIdeaUpdate {
  const TradeIdeaUpdate({required this.message, required this.price});

  factory TradeIdeaUpdate.fromJson(Map<String, dynamic> json) =>
      TradeIdeaUpdate(
        message: json['message']?.toString() ?? 'Signal updated.',
        price: _valueText(json['price']),
      );

  final String message;
  final String price;
}

String _rangeText(Object? raw) {
  if (raw is! Map) return '—';
  final low = _valueText(raw['low']);
  final high = _valueText(raw['high']);
  if (low == '—') return high;
  if (high == '—' || high == low) return low;
  return '$low – $high';
}

String _valueText(Object? value) {
  if (value == null) return '—';
  final text = value.toString().trim();
  return text.isEmpty ? '—' : text;
}
