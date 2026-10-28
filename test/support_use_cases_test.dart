import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/usecases/use_case.dart';
import 'package:tradex_mobile/features/support/domain/entities/support_entities.dart';
import 'package:tradex_mobile/features/support/domain/repositories/support_repository.dart';
import 'package:tradex_mobile/features/support/domain/usecases/support_use_cases.dart';

void main() {
  late _FakeSupportRepository repository;
  late SupportUseCases useCases;

  setUp(() {
    repository = _FakeSupportRepository();
    useCases = SupportUseCases(repository);
  });

  test('overview use case delegates to the domain repository', () async {
    final result = await useCases.getOverview(const NoParams());

    expect(result.agentsOnline, 3);
    expect(repository.lastAction, 'overview');
  });

  test('live chat use cases preserve identifiers and cursors', () async {
    final started = await useCases.startLiveChat(
      const StartSupportLiveChatParams('request-key'),
    );
    final events = await useCases.getEvents(
      const SupportChatEventsParams(chatUuid: 'chat-1', after: 9),
    );
    final message = await useCases.sendMessage(
      const SendSupportMessageParams(ticketUuid: 'ticket-1', message: 'Hello'),
    );

    expect(started.uuid, 'chat-1');
    expect(repository.lastIdempotencyKey, 'request-key');
    expect(repository.lastChatUuid, 'chat-1');
    expect(repository.lastCursor, 9);
    expect(repository.lastTicketUuid, 'ticket-1');
    expect(message.message, 'Hello');
    expect(events.nextCursor, 10);
  });
}

final class _FakeSupportRepository implements SupportRepository {
  String? lastAction;
  String? lastIdempotencyKey;
  String? lastChatUuid;
  String? lastTicketUuid;
  int? lastCursor;

  static final _session = SupportChatSession(
    uuid: 'chat-1',
    ticketUuid: 'ticket-1',
    ticketReference: 'TX-SUP-1',
    state: 'active',
    queuePosition: null,
    etaMinutes: null,
    agentsOnline: 3,
    assignedAgentName: 'Agent',
  );

  @override
  Future<SupportOverview> overview() async {
    lastAction = 'overview';
    return const SupportOverview(
      openTickets: 1,
      resolvedTickets: 2,
      closedTickets: 3,
      agentsOnline: 3,
    );
  }

  @override
  Future<List<SupportCategory>> categories() async => const [];

  @override
  Future<SupportChatSession> startLiveChat({
    required String idempotencyKey,
  }) async {
    lastIdempotencyKey = idempotencyKey;
    return _session;
  }

  @override
  Future<SupportChatSession> chat(String chatUuid) async {
    lastChatUuid = chatUuid;
    return _session;
  }

  @override
  Future<SupportChatSession> heartbeat(String chatUuid) => chat(chatUuid);

  @override
  Future<SupportChatSession> cancelChat(String chatUuid) => chat(chatUuid);

  @override
  Future<SupportChatSession> endChat(String chatUuid) => chat(chatUuid);

  @override
  Future<SupportChatEvents> events(String chatUuid, {int after = 0}) async {
    lastChatUuid = chatUuid;
    lastCursor = after;
    return SupportChatEvents(
      chat: _session,
      events: const [],
      nextCursor: after + 1,
    );
  }

  @override
  Future<SupportMessage> sendMessage({
    required String ticketUuid,
    required String message,
  }) async {
    lastTicketUuid = ticketUuid;
    return SupportMessage(
      uuid: 'message-1',
      cursor: 10,
      senderType: 'customer',
      message: message,
      createdAt: DateTime(2026),
    );
  }
}
