import '../entities/notification_entities.dart';
import '../repositories/notification_repository.dart';

final class LoadNotifications {
  const LoadNotifications(this._repository);
  final NotificationRepository _repository;
  Future<NotificationFeed> call(NotificationFeedFilter filter) =>
      _repository.feed(filter);
}
