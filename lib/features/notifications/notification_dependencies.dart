import '../../core/network/tradex_api_client.dart';
import 'data/notification_repository.dart';

class NotificationDependencies {
  NotificationDependencies(TradeXApiClient apiClient)
    : repository = NotificationRepository(apiClient);

  final NotificationDataSource repository;
}
