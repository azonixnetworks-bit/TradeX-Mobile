import 'no_trade_zone_warning.dart';

abstract interface class MarketNewsRepositoryContract {
  Future<List<MarketNewsItem>> latest({
    int limit = 4,
    bool forceRefresh = false,
  });

  Future<List<MarketNewsItem>> today({
    DateTime? now,
    bool forceRefresh = false,
  });
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
}
