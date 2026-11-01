import '../../core/network/tradex_api_client.dart';
import 'data/datasources/notification_permission_service.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';

class NotificationDependencies {
  NotificationDependencies(TradeXApiClient apiClient)
    : repository = NotificationRepositoryImpl(apiClient),
      permissionRepository = NotificationPermissionService();

  final NotificationRepository repository;
  final NotificationPermissionRepository permissionRepository;
}
