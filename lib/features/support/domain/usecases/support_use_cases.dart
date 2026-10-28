import '../../../../core/usecases/use_case.dart';
import '../entities/support_entities.dart';
import '../repositories/support_repository.dart';

final class SupportUseCases {
  SupportUseCases(SupportRepository repository)
    : getOverview = GetSupportOverview(repository),
      getCategories = GetSupportCategories(repository),
      startLiveChat = StartSupportLiveChat(repository),
      getChat = GetSupportChat(repository),
      heartbeat = SendSupportHeartbeat(repository),
      cancelChat = CancelSupportChat(repository),
      endChat = EndSupportChat(repository),
      getEvents = GetSupportChatEvents(repository),
      sendMessage = SendSupportMessage(repository);

  final GetSupportOverview getOverview;
  final GetSupportCategories getCategories;
  final StartSupportLiveChat startLiveChat;
  final GetSupportChat getChat;
  final SendSupportHeartbeat heartbeat;
  final CancelSupportChat cancelChat;
  final EndSupportChat endChat;
  final GetSupportChatEvents getEvents;
  final SendSupportMessage sendMessage;
}

final class GetSupportOverview implements UseCase<SupportOverview, NoParams> {
  const GetSupportOverview(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportOverview> call(NoParams input) => _repository.overview();
}

final class GetSupportCategories
    implements UseCase<List<SupportCategory>, NoParams> {
  const GetSupportCategories(this._repository);
  final SupportRepository _repository;

  @override
  Future<List<SupportCategory>> call(NoParams input) =>
      _repository.categories();
}

final class StartSupportLiveChat
    implements UseCase<SupportChatSession, StartSupportLiveChatParams> {
  const StartSupportLiveChat(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportChatSession> call(StartSupportLiveChatParams input) =>
      _repository.startLiveChat(idempotencyKey: input.idempotencyKey);
}

final class GetSupportChat implements UseCase<SupportChatSession, String> {
  const GetSupportChat(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportChatSession> call(String input) => _repository.chat(input);
}

final class SendSupportHeartbeat
    implements UseCase<SupportChatSession, String> {
  const SendSupportHeartbeat(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportChatSession> call(String input) => _repository.heartbeat(input);
}

final class CancelSupportChat implements UseCase<SupportChatSession, String> {
  const CancelSupportChat(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportChatSession> call(String input) =>
      _repository.cancelChat(input);
}

final class EndSupportChat implements UseCase<SupportChatSession, String> {
  const EndSupportChat(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportChatSession> call(String input) => _repository.endChat(input);
}

final class GetSupportChatEvents
    implements UseCase<SupportChatEvents, SupportChatEventsParams> {
  const GetSupportChatEvents(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportChatEvents> call(SupportChatEventsParams input) =>
      _repository.events(input.chatUuid, after: input.after);
}

final class SendSupportMessage
    implements UseCase<SupportMessage, SendSupportMessageParams> {
  const SendSupportMessage(this._repository);
  final SupportRepository _repository;

  @override
  Future<SupportMessage> call(SendSupportMessageParams input) => _repository
      .sendMessage(ticketUuid: input.ticketUuid, message: input.message);
}

final class StartSupportLiveChatParams {
  const StartSupportLiveChatParams(this.idempotencyKey);
  final String idempotencyKey;
}

final class SupportChatEventsParams {
  const SupportChatEventsParams({required this.chatUuid, this.after = 0});
  final String chatUuid;
  final int after;
}

final class SendSupportMessageParams {
  const SendSupportMessageParams({
    required this.ticketUuid,
    required this.message,
  });
  final String ticketUuid;
  final String message;
}
