import 'package:uuid/uuid.dart';

import '../../../core/network/tradex_api_client.dart';

typedef SupportJson = Map<String, dynamic>;

class SupportRepository {
  const SupportRepository(this.apiClient);

  final TradeXApiClient apiClient;

  static const bool phaseOneAvailable = true;
  static const String unavailableMessage =
      'This support action is not connected yet. Please try live chat.';

  Future<SupportOverview> overview() async {
    final data = _data(await apiClient.getJson('/api/v1/support/overview'));
    return SupportOverview.fromJson(data);
  }

  Future<List<SupportCategory>> categories() async {
    final response = await apiClient.getJson('/api/v1/support/categories');
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => SupportCategory.fromJson(_map(item)))
        .where((item) => item.uuid.isNotEmpty)
        .toList(growable: false);
  }

  Future<SupportChatSession> startLiveChat({
    required String idempotencyKey,
  }) async {
    final availableCategories = await categories();
    if (availableCategories.isEmpty) {
      throw StateError('Live support categories are unavailable right now.');
    }
    final category = availableCategories.firstWhere(
      (item) => item.slug == 'other-enquiries',
      orElse: () => availableCategories.first,
    );
    final response = await apiClient.postJsonWithHeaders(
      '/api/v1/support/live-chat/start',
      {
        'category_uuid': category.uuid,
        'subject': 'Mobile app live support request',
        'description': 'The customer started a secure live support conversation from the TradeX mobile app.',
        'requested_urgency': 'normal',
      },
      {'Idempotency-Key': idempotencyKey},
    );
    return SupportChatSession.fromJson(_data(response));
  }

  Future<SupportChatSession> chat(String chatUuid) async {
    final response = await apiClient.getJson(
      '/api/v1/support/live-chat/$chatUuid',
    );
    return SupportChatSession.fromJson(_data(response));
  }

  Future<SupportChatSession> heartbeat(String chatUuid) async {
    final response = await apiClient.postJson(
      '/api/v1/support/live-chat/$chatUuid/heartbeat',
      const {},
    );
    return SupportChatSession.fromJson(_data(response));
  }

  Future<SupportChatSession> cancelChat(String chatUuid) async {
    final response = await apiClient.postJson(
      '/api/v1/support/live-chat/$chatUuid/cancel',
      const {},
    );
    return SupportChatSession.fromJson(_data(response));
  }

  Future<SupportChatSession> endChat(String chatUuid) async {
    final response = await apiClient.postJson(
      '/api/v1/support/live-chat/$chatUuid/end',
      const {},
    );
    return SupportChatSession.fromJson(_data(response));
  }

  Future<SupportChatEvents> events(String chatUuid, {int after = 0}) async {
    final response = await apiClient.getJson(
      '/api/v1/support/live-chat/$chatUuid/events?after=$after',
    );
    return SupportChatEvents.fromJson(_data(response));
  }

  Future<SupportMessage> sendMessage({
    required String ticketUuid,
    required String message,
  }) async {
    final response = await apiClient.postJsonWithHeaders(
      '/api/v1/support/tickets/$ticketUuid/messages',
      {'message': message.trim()},
      {'Idempotency-Key': const Uuid().v4()},
    );
    return SupportMessage.fromJson(_data(response));
  }

  static SupportJson _data(SupportJson response) {
    final value = response['data'];
    return value is Map ? _map(value) : response;
  }
}

class SupportCategory {
  const SupportCategory({
    required this.uuid,
    required this.slug,
    required this.label,
  });

  factory SupportCategory.fromJson(SupportJson json) => SupportCategory(
    uuid: _text(json['uuid']),
    slug: _text(json['slug']),
    label: _text(json['label'], 'Support'),
  );

  final String uuid;
  final String slug;
  final String label;
}

class SupportOverview {
  const SupportOverview({
    required this.openTickets,
    required this.resolvedTickets,
    required this.closedTickets,
    required this.agentsOnline,
  });

  factory SupportOverview.fromJson(SupportJson json) {
    final counts = _map(json['ticket_counts']);
    final liveChat = _map(json['live_chat']);
    return SupportOverview(
      openTickets: _integer(counts['open']),
      resolvedTickets: _integer(counts['resolved']),
      closedTickets: _integer(counts['closed']),
      agentsOnline: _integer(liveChat['agents_online']),
    );
  }

  final int openTickets;
  final int resolvedTickets;
  final int closedTickets;
  final int agentsOnline;
}

class SupportChatSession {
  const SupportChatSession({
    required this.uuid,
    required this.ticketUuid,
    required this.ticketReference,
    required this.state,
    required this.queuePosition,
    required this.etaMinutes,
    required this.agentsOnline,
    required this.assignedAgentName,
  });

  factory SupportChatSession.fromJson(SupportJson json) {
    final agent = _map(json['assigned_agent']);
    return SupportChatSession(
      uuid: _text(json['uuid']),
      ticketUuid: _text(json['ticket_uuid']),
      ticketReference: _text(json['ticket_reference']),
      state: _text(json['state'], 'queued'),
      queuePosition: _nullableInteger(json['queue_position']),
      etaMinutes: _nullableInteger(json['eta_minutes']),
      agentsOnline: _integer(json['agents_online']),
      assignedAgentName: _nullableText(agent['name']),
    );
  }

  final String uuid;
  final String ticketUuid;
  final String ticketReference;
  final String state;
  final int? queuePosition;
  final int? etaMinutes;
  final int agentsOnline;
  final String? assignedAgentName;

  bool get isConnected => state == 'assigned' || state == 'active';
  bool get isEnded => const ['ended', 'cancelled'].contains(state);
}

class SupportMessage {
  const SupportMessage({
    required this.uuid,
    required this.cursor,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(SupportJson json) => SupportMessage(
    uuid: _text(json['uuid']),
    cursor: _integer(json['cursor']),
    senderType: _text(json['sender_type'], 'customer'),
    message: _text(json['message']),
    createdAt:
        DateTime.tryParse(_text(json['created_at']))?.toLocal() ??
        DateTime.now(),
  );

  final String uuid;
  final int cursor;
  final String senderType;
  final String message;
  final DateTime createdAt;

  bool get fromCustomer => senderType == 'customer';
}

class SupportChatEvents {
  const SupportChatEvents({
    required this.chat,
    required this.events,
    required this.nextCursor,
  });

  factory SupportChatEvents.fromJson(SupportJson json) {
    final rawEvents = json['events'];
    return SupportChatEvents(
      chat: SupportChatSession.fromJson(_map(json['chat'])),
      events: rawEvents is List
          ? rawEvents
                .whereType<Map>()
                .map((item) => SupportMessage.fromJson(_map(item)))
                .toList(growable: false)
          : const [],
      nextCursor: _integer(json['next_cursor']),
    );
  }

  final SupportChatSession chat;
  final List<SupportMessage> events;
  final int nextCursor;
}

SupportJson _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

String _text(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _integer(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String number => int.tryParse(number) ?? 0,
  bool boolean => boolean ? 1 : 0,
  _ => 0,
};

int? _nullableInteger(Object? value) {
  if (value == null) return null;
  return switch (value) {
    int number => number,
    num number => number.toInt(),
    String number => int.tryParse(number),
    _ => null,
  };
}
