class SupportCategory {
  const SupportCategory({
    required this.uuid,
    required this.slug,
    required this.label,
  });

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

  final SupportChatSession chat;
  final List<SupportMessage> events;
  final int nextCursor;
}
