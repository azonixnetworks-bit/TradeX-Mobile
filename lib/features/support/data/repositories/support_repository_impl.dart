import 'package:uuid/uuid.dart';

import '../../domain/entities/support_entities.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_data_source.dart';
import '../models/support_models.dart';

final class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._remoteDataSource);

  final SupportRemoteDataSource _remoteDataSource;

  @override
  Future<SupportOverview> overview() async =>
      SupportOverviewModel.fromJson(await _remoteDataSource.overview())
          .toEntity();

  @override
  Future<List<SupportCategory>> categories() async =>
      (await _remoteDataSource.categories())
          .map(SupportCategoryModel.fromJson)
          .where((item) => item.uuid.isNotEmpty)
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
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
    final json = await _remoteDataSource.startLiveChat(
      categoryUuid: category.uuid,
      idempotencyKey: idempotencyKey,
    );
    return SupportChatSessionModel.fromJson(json).toEntity();
  }

  @override
  Future<SupportChatSession> chat(String chatUuid) async =>
      SupportChatSessionModel.fromJson(await _remoteDataSource.chat(chatUuid))
          .toEntity();

  @override
  Future<SupportChatSession> heartbeat(String chatUuid) async =>
      SupportChatSessionModel.fromJson(
        await _remoteDataSource.heartbeat(chatUuid),
      ).toEntity();

  @override
  Future<SupportChatSession> cancelChat(String chatUuid) async =>
      SupportChatSessionModel.fromJson(
        await _remoteDataSource.cancelChat(chatUuid),
      ).toEntity();

  @override
  Future<SupportChatSession> endChat(String chatUuid) async =>
      SupportChatSessionModel.fromJson(
        await _remoteDataSource.endChat(chatUuid),
      ).toEntity();

  @override
  Future<SupportChatEvents> events(String chatUuid, {int after = 0}) async =>
      SupportChatEventsModel.fromJson(
        await _remoteDataSource.events(chatUuid, after: after),
      ).toEntity();

  @override
  Future<SupportMessage> sendMessage({
    required String ticketUuid,
    required String message,
  }) async => SupportMessageModel.fromJson(
    await _remoteDataSource.sendMessage(
      ticketUuid: ticketUuid,
      message: message,
      idempotencyKey: const Uuid().v4(),
    ),
  ).toEntity();
}
