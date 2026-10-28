import '../../domain/entities/support_entities.dart';

typedef SupportJson = Map<String, dynamic>;

final class SupportCategoryModel {
  const SupportCategoryModel({
    required this.uuid,
    required this.slug,
    required this.label,
  });

  factory SupportCategoryModel.fromJson(SupportJson json) =>
      SupportCategoryModel(
        uuid: supportText(json['uuid']),
        slug: supportText(json['slug']),
        label: supportText(json['label'], 'Support'),
      );

  final String uuid;
  final String slug;
  final String label;

  SupportCategory toEntity() =>
      SupportCategory(uuid: uuid, slug: slug, label: label);
}

final class SupportOverviewModel {
  const SupportOverviewModel({
    required this.openTickets,
    required this.resolvedTickets,
    required this.closedTickets,
    required this.agentsOnline,
  });

  factory SupportOverviewModel.fromJson(SupportJson json) {
    final counts = supportMap(json['ticket_counts']);
    final liveChat = supportMap(json['live_chat']);
    return SupportOverviewModel(
      openTickets: supportInteger(counts['open']),
      resolvedTickets: supportInteger(counts['resolved']),
      closedTickets: supportInteger(counts['closed']),
      agentsOnline: supportInteger(liveChat['agents_online']),
    );
  }

  final int openTickets;
  final int resolvedTickets;
  final int closedTickets;
  final int agentsOnline;

  SupportOverview toEntity() => SupportOverview(
    openTickets: openTickets,
    resolvedTickets: resolvedTickets,
    closedTickets: closedTickets,
    agentsOnline: agentsOnline,
  );
}

final class SupportChatSessionModel {
  const SupportChatSessionModel({
    required this.uuid,
    required this.ticketUuid,
    required this.ticketReference,
    required this.state,
    required this.queuePosition,
    required this.etaMinutes,
    required this.agentsOnline,
    required this.assignedAgentName,
  });

  factory SupportChatSessionModel.fromJson(SupportJson json) {
    final agent = supportMap(json['assigned_agent']);
    return SupportChatSessionModel(
      uuid: supportText(json['uuid']),
      ticketUuid: supportText(json['ticket_uuid']),
      ticketReference: supportText(json['ticket_reference']),
      state: supportText(json['state'], 'queued'),
      queuePosition: supportNullableInteger(json['queue_position']),
      etaMinutes: supportNullableInteger(json['eta_minutes']),
      agentsOnline: supportInteger(json['agents_online']),
      assignedAgentName: supportNullableText(agent['name']),
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

  SupportChatSession toEntity() => SupportChatSession(
    uuid: uuid,
    ticketUuid: ticketUuid,
    ticketReference: ticketReference,
    state: state,
    queuePosition: queuePosition,
    etaMinutes: etaMinutes,
    agentsOnline: agentsOnline,
    assignedAgentName: assignedAgentName,
  );
}

final class SupportMessageModel {
  const SupportMessageModel({
    required this.uuid,
    required this.cursor,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessageModel.fromJson(SupportJson json) => SupportMessageModel(
    uuid: supportText(json['uuid']),
    cursor: supportInteger(json['cursor']),
    senderType: supportText(json['sender_type'], 'customer'),
    message: supportText(json['message']),
    createdAt:
        DateTime.tryParse(supportText(json['created_at']))?.toLocal() ??
        DateTime.now(),
  );

  final String uuid;
  final int cursor;
  final String senderType;
  final String message;
  final DateTime createdAt;

  SupportMessage toEntity() => SupportMessage(
    uuid: uuid,
    cursor: cursor,
    senderType: senderType,
    message: message,
    createdAt: createdAt,
  );
}

final class SupportChatEventsModel {
  const SupportChatEventsModel({
    required this.chat,
    required this.events,
    required this.nextCursor,
  });

  factory SupportChatEventsModel.fromJson(SupportJson json) {
    final rawEvents = json['events'];
    return SupportChatEventsModel(
      chat: SupportChatSessionModel.fromJson(supportMap(json['chat'])),
      events: rawEvents is List
          ? rawEvents
                .whereType<Map>()
                .map((item) => SupportMessageModel.fromJson(supportMap(item)))
                .toList(growable: false)
          : const [],
      nextCursor: supportInteger(json['next_cursor']),
    );
  }

  final SupportChatSessionModel chat;
  final List<SupportMessageModel> events;
  final int nextCursor;

  SupportChatEvents toEntity() => SupportChatEvents(
    chat: chat.toEntity(),
    events: events.map((event) => event.toEntity()).toList(growable: false),
    nextCursor: nextCursor,
  );
}

SupportJson supportMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

String supportText(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? supportNullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int supportInteger(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String number => int.tryParse(number) ?? 0,
  bool boolean => boolean ? 1 : 0,
  _ => 0,
};

int? supportNullableInteger(Object? value) {
  if (value == null) return null;
  return switch (value) {
    int number => number,
    num number => number.toInt(),
    String number => int.tryParse(number),
    _ => null,
  };
}
