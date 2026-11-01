enum NotificationFeedFilter { all, unread, trading, system }

class TradeXNotification {
  const TradeXNotification({
    required this.uuid,
    required this.notificationUuid,
    required this.category,
    required this.priority,
    required this.title,
    required this.body,
    required this.actionType,
    required this.isRead,
    required this.publishedAt,
    this.actionResourceUuid,
    this.readAt,
    this.expiresAt,
  });

  factory TradeXNotification.fromJson(Map<String, dynamic> json) {
    final action = _map(json['action']);
    return TradeXNotification(
      uuid: _text(json['uuid']),
      notificationUuid: _text(json['notification_uuid']),
      category: _text(json['category'], 'GENERAL').toUpperCase(),
      priority: _text(json['priority'], 'NORMAL').toUpperCase(),
      title: _text(json['title'], 'TradeX update'),
      body: _text(json['body']),
      actionType: _text(action['type'], 'NONE').toUpperCase(),
      actionResourceUuid: _nullableText(action['resource_uuid']),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: _date(json['read_at']),
      publishedAt: _date(json['published_at']) ?? DateTime.now().toUtc(),
      expiresAt: _date(json['expires_at']),
    );
  }

  final String uuid;
  final String notificationUuid;
  final String category;
  final String priority;
  final String title;
  final String body;
  final String actionType;
  final String? actionResourceUuid;
  final bool isRead;
  final DateTime? readAt;
  final DateTime publishedAt;
  final DateTime? expiresAt;

  bool get hasAction => actionType != 'NONE';
  bool get isTrading => category == 'TRADE_IDEA';
  bool get isSystem => category == 'SYSTEM' || category == 'SECURITY';

  TradeXNotification copyWith({bool? isRead, DateTime? readAt}) =>
      TradeXNotification(
        uuid: uuid,
        notificationUuid: notificationUuid,
        category: category,
        priority: priority,
        title: title,
        body: body,
        actionType: actionType,
        actionResourceUuid: actionResourceUuid,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        publishedAt: publishedAt,
        expiresAt: expiresAt,
      );
}

class NotificationFeed {
  const NotificationFeed({
    required this.items,
    required this.unreadCount,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  factory NotificationFeed.fromJson(Map<String, dynamic> json) {
    final pagination = _map(json['pagination']);
    final rawItems = json['items'];
    return NotificationFeed(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => TradeXNotification.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const [],
      unreadCount: _integer(json['unread_count']),
      total: _integer(pagination['total']),
      currentPage: _integer(pagination['current_page'], 1),
      lastPage: _integer(pagination['last_page'], 1),
    );
  }

  final List<TradeXNotification> items;
  final int unreadCount;
  final int total;
  final int currentPage;
  final int lastPage;
}

class PushDeviceStatus {
  const PushDeviceStatus({
    required this.registered,
    required this.deliveryEnabled,
    required this.platform,
    required this.provider,
  });

  const PushDeviceStatus.unavailable()
    : registered = false,
      deliveryEnabled = false,
      platform = '',
      provider = '';

  factory PushDeviceStatus.fromJson(Map<String, dynamic> json) =>
      PushDeviceStatus(
        registered: json['registered'] == true,
        deliveryEnabled: json['delivery_enabled'] == true,
        platform: _text(json['platform']),
        provider: _text(json['provider']),
      );

  final bool registered;
  final bool deliveryEnabled;
  final String platform;
  final String provider;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.tradeIdeas = true,
    this.economicNews = true,
    this.fundedAccounts = true,
    this.copyTrading = true,
    this.learning = true,
    this.affiliate = true,
    this.support = true,
  });

  final bool tradeIdeas;
  final bool economicNews;
  final bool fundedAccounts;
  final bool copyTrading;
  final bool learning;
  final bool affiliate;
  final bool support;

  NotificationPreferences copyWith({
    bool? tradeIdeas,
    bool? economicNews,
    bool? fundedAccounts,
    bool? copyTrading,
    bool? learning,
    bool? affiliate,
    bool? support,
  }) => NotificationPreferences(
    tradeIdeas: tradeIdeas ?? this.tradeIdeas,
    economicNews: economicNews ?? this.economicNews,
    fundedAccounts: fundedAccounts ?? this.fundedAccounts,
    copyTrading: copyTrading ?? this.copyTrading,
    learning: learning ?? this.learning,
    affiliate: affiliate ?? this.affiliate,
    support: support ?? this.support,
  );
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const <String, dynamic>{};

String _text(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

int _integer(Object? value, [int fallback = 0]) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String number => int.tryParse(number) ?? fallback,
  _ => fallback,
};

DateTime? _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();
