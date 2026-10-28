import '../entities/support_entities.dart';

abstract interface class SupportRepository {
  Future<SupportOverview> overview();

  Future<List<SupportCategory>> categories();

  Future<SupportChatSession> startLiveChat({required String idempotencyKey});

  Future<SupportChatSession> chat(String chatUuid);

  Future<SupportChatSession> heartbeat(String chatUuid);

  Future<SupportChatSession> cancelChat(String chatUuid);

  Future<SupportChatSession> endChat(String chatUuid);

  Future<SupportChatEvents> events(String chatUuid, {int after = 0});

  Future<SupportMessage> sendMessage({
    required String ticketUuid,
    required String message,
  });
}
