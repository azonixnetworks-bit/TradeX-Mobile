import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/tradex_api_client.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationDataSource {
  NotificationRepositoryImpl(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<NotificationFeed> feed(NotificationFeedFilter filter) async {
    final query = <String, String>{'per_page': '50'};
    switch (filter) {
      case NotificationFeedFilter.all:
        break;
      case NotificationFeedFilter.unread:
        query['status'] = 'UNREAD';
      case NotificationFeedFilter.trading:
        query['category'] = 'TRADE_IDEA';
      case NotificationFeedFilter.system:
        query['category'] = 'SYSTEM';
    }
    final uri = Uri(path: '/api/v1/notifications', queryParameters: query);
    final response = await _apiClient.getJson(uri.toString());
    return NotificationFeed.fromJson(_data(response));
  }

  @override
  Future<TradeXNotification> detail(String uuid) async {
    final response = await _apiClient.getJson('/api/v1/notifications/$uuid');
    return TradeXNotification.fromJson(_data(response));
  }

  @override
  Future<int> markRead(String uuid) async {
    final response = await _apiClient.patchJson(
      '/api/v1/notifications/$uuid/read',
      const {},
    );
    return _integer(_data(response)['unread_count']);
  }

  @override
  Future<int> markAllRead() async {
    final response = await _apiClient.patchJson(
      '/api/v1/notifications/read-all',
      const {},
    );
    return _integer(_data(response)['unread_count']);
  }

  @override
  Future<PushDeviceStatus> pushStatus() async {
    final response = await _apiClient.getJson('/api/v1/push/device-token');
    return PushDeviceStatus.fromJson(_data(response));
  }

  @override
  Future<NotificationPreferences> preferences() async {
    final store = await SharedPreferences.getInstance();
    return NotificationPreferences(
      tradeIdeas: store.getBool(_key('trade_ideas')) ?? true,
      economicNews: store.getBool(_key('economic_news')) ?? true,
      fundedAccounts: store.getBool(_key('funded_accounts')) ?? true,
      copyTrading: store.getBool(_key('copy_trading')) ?? true,
      learning: store.getBool(_key('learning')) ?? true,
      affiliate: store.getBool(_key('affiliate')) ?? true,
      support: store.getBool(_key('support')) ?? true,
    );
  }

  @override
  Future<void> savePreferences(NotificationPreferences value) async {
    final store = await SharedPreferences.getInstance();
    await Future.wait([
      store.setBool(_key('trade_ideas'), value.tradeIdeas),
      store.setBool(_key('economic_news'), value.economicNews),
      store.setBool(_key('funded_accounts'), value.fundedAccounts),
      store.setBool(_key('copy_trading'), value.copyTrading),
      store.setBool(_key('learning'), value.learning),
      store.setBool(_key('affiliate'), value.affiliate),
      store.setBool(_key('support'), value.support),
    ]);
  }

  static String _key(String name) => 'tradex.notification.preference.$name';

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final value = response['data'];
    return value is Map
        ? value.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
  }

  static int _integer(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String number => int.tryParse(number) ?? 0,
    _ => 0,
  };
}
