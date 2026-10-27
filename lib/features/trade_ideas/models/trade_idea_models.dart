typedef TradeIdeaJson = Map<String, dynamic>;

class TradeIdeaPage {
  const TradeIdeaPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TradeIdeaSummary> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

class TradeIdeaSummary {
  const TradeIdeaSummary({
    required this.uuid,
    required this.title,
    required this.summary,
    required this.category,
    required this.marketRegion,
    required this.symbol,
    required this.instrumentName,
    required this.direction,
    required this.timeframe,
    required this.status,
    required this.entry,
    required this.stopLoss,
    required this.targetsTotal,
    required this.targetsHit,
    required this.chartAvailable,
    required this.tradingViewUrl,
    required this.publishedAt,
    required this.closedAt,
    required this.closeOutcome,
    required this.reactions,
  });

  factory TradeIdeaSummary.fromJson(TradeIdeaJson json) {
    final targets = tradeIdeaMap(json['targets']);
    return TradeIdeaSummary(
      uuid: tradeIdeaText(json['uuid']),
      title: tradeIdeaText(json['title']),
      summary: tradeIdeaText(json['summary']),
      category: tradeIdeaText(json['category']).toUpperCase(),
      marketRegion: tradeIdeaText(json['market_region']).toUpperCase(),
      symbol: tradeIdeaText(json['symbol'], fallback: 'MARKET').toUpperCase(),
      instrumentName: tradeIdeaText(json['instrument_name']),
      direction: tradeIdeaText(json['direction'], fallback: '—').toUpperCase(),
      timeframe: tradeIdeaText(json['timeframe'], fallback: '—').toUpperCase(),
      status: tradeIdeaText(
        json['status'],
        fallback: 'PUBLISHED',
      ).toUpperCase(),
      entry: TradeIdeaEntry.fromJson(tradeIdeaMap(json['entry'])),
      stopLoss: TradeIdeaStopLoss.fromJson(tradeIdeaMap(json['stop_loss'])),
      targetsTotal: tradeIdeaInt(targets['total']),
      targetsHit: tradeIdeaInt(targets['hit']),
      chartAvailable: json['chart_available'] == true,
      tradingViewUrl: tradeIdeaNullableText(json['tradingview_url']),
      publishedAt: tradeIdeaDate(json['published_at']),
      closedAt: tradeIdeaDate(json['closed_at']),
      closeOutcome: tradeIdeaNullableText(json['close_outcome']),
      reactions: TradeIdeaReactionSummary.fromJson(
        tradeIdeaMap(json['reactions']),
      ),
    );
  }

  final String uuid;
  final String title;
  final String summary;
  final String category;
  final String marketRegion;
  final String symbol;
  final String instrumentName;
  final String direction;
  final String timeframe;
  final String status;
  final TradeIdeaEntry entry;
  final TradeIdeaStopLoss stopLoss;
  final int targetsTotal;
  final int targetsHit;
  final bool chartAvailable;
  final String? tradingViewUrl;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  final String? closeOutcome;
  final TradeIdeaReactionSummary reactions;
}

class TradeIdeaDetail {
  const TradeIdeaDetail({
    required this.summary,
    required this.analysis,
    required this.targets,
    required this.timeline,
    required this.close,
    required this.riskNotice,
    required this.shareActionUrl,
    required this.shareCardUrl,
  });

  factory TradeIdeaDetail.fromJson(TradeIdeaJson json) {
    final targets = tradeIdeaList(json['targets'])
        .map(TradeIdeaTarget.fromJson)
        .toList(growable: false);
    final summary = TradeIdeaSummary.fromJson({
      ...json,
      'targets': {
        'total': targets.length,
        'hit': targets.where((target) => target.isHit).length,
      },
    });
    return TradeIdeaDetail(
      summary: summary,
      analysis: tradeIdeaText(json['analysis']),
      targets: targets,
      timeline: tradeIdeaList(json['timeline'])
          .map(TradeIdeaTimelineItem.fromJson)
          .toList(growable: false),
      close: TradeIdeaClose.fromJson(tradeIdeaMap(json['close'])),
      riskNotice: tradeIdeaText(
        json['risk_notice'],
        fallback: 'Trade Ideas are educational market analysis and do not guarantee profit. Apply your own risk management.',
      ),
      shareActionUrl: tradeIdeaNullableText(
        tradeIdeaMap(json['actions'])['share_action_url'],
      ),
      shareCardUrl: tradeIdeaNullableText(
        tradeIdeaMap(json['actions'])['share_card_url'],
      ),
    );
  }

  final TradeIdeaSummary summary;
  final String analysis;
  final List<TradeIdeaTarget> targets;
  final List<TradeIdeaTimelineItem> timeline;
  final TradeIdeaClose close;
  final String riskNotice;
  final String? shareActionUrl;
  final String? shareCardUrl;

  TradeIdeaDetail copyWith({TradeIdeaReactionSummary? reactions}) {
    final current = summary;
    return TradeIdeaDetail(
      summary: TradeIdeaSummary(
        uuid: current.uuid,
        title: current.title,
        summary: current.summary,
        category: current.category,
        marketRegion: current.marketRegion,
        symbol: current.symbol,
        instrumentName: current.instrumentName,
        direction: current.direction,
        timeframe: current.timeframe,
        status: current.status,
        entry: current.entry,
        stopLoss: current.stopLoss,
        targetsTotal: current.targetsTotal,
        targetsHit: current.targetsHit,
        chartAvailable: current.chartAvailable,
        tradingViewUrl: current.tradingViewUrl,
        publishedAt: current.publishedAt,
        closedAt: current.closedAt,
        closeOutcome: current.closeOutcome,
        reactions: reactions ?? current.reactions,
      ),
      analysis: analysis,
      targets: targets,
      timeline: timeline,
      close: close,
      riskNotice: riskNotice,
      shareActionUrl: shareActionUrl,
      shareCardUrl: shareCardUrl,
    );
  }
}

class TradeIdeaEntry {
  const TradeIdeaEntry({this.low, this.high, this.actual, this.triggeredAt});

  factory TradeIdeaEntry.fromJson(TradeIdeaJson json) => TradeIdeaEntry(
    low: tradeIdeaNullableText(json['low']),
    high: tradeIdeaNullableText(json['high']),
    actual: tradeIdeaNullableText(json['actual']),
    triggeredAt: tradeIdeaDate(json['triggered_at']),
  );

  final String? low;
  final String? high;
  final String? actual;
  final DateTime? triggeredAt;

  String get display {
    if (actual != null) return actual!;
    if (low == null && high == null) return '—';
    if (low == null) return '≤ $high';
    if (high == null) return '≥ $low';
    if (low == high) return low!;
    return '$low – $high';
  }
}

class TradeIdeaStopLoss {
  const TradeIdeaStopLoss({this.initial, this.current});

  factory TradeIdeaStopLoss.fromJson(TradeIdeaJson json) => TradeIdeaStopLoss(
    initial: tradeIdeaNullableText(json['initial']),
    current: tradeIdeaNullableText(json['current']),
  );

  final String? initial;
  final String? current;
  String get display => current ?? initial ?? '—';
}

class TradeIdeaTarget {
  const TradeIdeaTarget({
    required this.label,
    required this.price,
    required this.sortOrder,
    required this.isHit,
    this.hitAt,
    this.hitPrice,
  });

  factory TradeIdeaTarget.fromJson(TradeIdeaJson json) => TradeIdeaTarget(
    label: tradeIdeaText(json['label'], fallback: 'TP'),
    price: tradeIdeaText(json['price'], fallback: '—'),
    sortOrder: tradeIdeaInt(json['sort_order']),
    isHit: json['is_hit'] == true,
    hitAt: tradeIdeaDate(json['hit_at']),
    hitPrice: tradeIdeaNullableText(json['hit_price']),
  );

  final String label;
  final String price;
  final int sortOrder;
  final bool isHit;
  final DateTime? hitAt;
  final String? hitPrice;
}

class TradeIdeaTimelineItem {
  const TradeIdeaTimelineItem({
    required this.type,
    required this.message,
    this.price,
    this.targetLabel,
    this.targetPrice,
    this.createdAt,
  });

  factory TradeIdeaTimelineItem.fromJson(TradeIdeaJson json) {
    final target = tradeIdeaMap(json['target']);
    return TradeIdeaTimelineItem(
      type: tradeIdeaText(json['type'], fallback: 'UPDATE').toUpperCase(),
      message: tradeIdeaText(json['message'], fallback: 'Trade idea updated.'),
      price: tradeIdeaNullableText(json['price']),
      targetLabel: tradeIdeaNullableText(target['label']),
      targetPrice: tradeIdeaNullableText(target['price']),
      createdAt: tradeIdeaDate(json['created_at']),
    );
  }

  final String type;
  final String message;
  final String? price;
  final String? targetLabel;
  final String? targetPrice;
  final DateTime? createdAt;
}

class TradeIdeaClose {
  const TradeIdeaClose({this.outcome, this.price, this.note, this.closedAt});

  factory TradeIdeaClose.fromJson(TradeIdeaJson json) => TradeIdeaClose(
    outcome: tradeIdeaNullableText(json['outcome']),
    price: tradeIdeaNullableText(json['price']),
    note: tradeIdeaNullableText(json['note']),
    closedAt: tradeIdeaDate(json['closed_at']),
  );

  final String? outcome;
  final String? price;
  final String? note;
  final DateTime? closedAt;
}

class TradeIdeaReactionSummary {
  const TradeIdeaReactionSummary({
    required this.likes,
    required this.dislikes,
    this.viewerReaction,
  });

  factory TradeIdeaReactionSummary.fromJson(TradeIdeaJson json) =>
      TradeIdeaReactionSummary(
        likes: tradeIdeaInt(json['likes_count']),
        dislikes: tradeIdeaInt(json['dislikes_count']),
        viewerReaction: tradeIdeaNullableText(json['viewer_reaction']),
      );

  final int likes;
  final int dislikes;
  final String? viewerReaction;

  TradeIdeaReactionSummary optimistic(String? next) {
    var nextLikes = likes;
    var nextDislikes = dislikes;
    if (viewerReaction == 'LIKE') nextLikes--;
    if (viewerReaction == 'DISLIKE') nextDislikes--;
    if (next == 'LIKE') nextLikes++;
    if (next == 'DISLIKE') nextDislikes++;
    return TradeIdeaReactionSummary(
      likes: nextLikes < 0 ? 0 : nextLikes,
      dislikes: nextDislikes < 0 ? 0 : nextDislikes,
      viewerReaction: next,
    );
  }
}

TradeIdeaJson tradeIdeaMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

List<TradeIdeaJson> tradeIdeaList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const <TradeIdeaJson>[];

String tradeIdeaText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? tradeIdeaNullableText(Object? value) {
  final text = tradeIdeaText(value);
  return text.isEmpty ? null : text;
}

int tradeIdeaInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

DateTime? tradeIdeaDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();
