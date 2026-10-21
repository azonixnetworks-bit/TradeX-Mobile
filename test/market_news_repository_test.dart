import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/features/home/data/market_news_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses upcoming published events when the live feed is empty', () async {
    final store = SecureSessionStore();
    final api = _EconomicNewsApiClient(store, DeviceIdentity(store));

    final news = await MarketNewsRepository(api).latest();

    expect(api.paths.first, startsWith('/api/v1/economic-news/live'));
    expect(api.paths.last, startsWith('/api/v1/economic-news/events?from='));
    expect(news, hasLength(1));
    expect(news.single.title, 'US CPI');
    expect(news.single.summary, contains('Forecast 2.8%'));
    expect(news.single.currency, 'USD');
  });
}

class _EconomicNewsApiClient extends TradeXApiClient {
  _EconomicNewsApiClient(super.sessionStore, super.deviceIdentity);

  final List<String> paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    paths.add(path);
    if (path.startsWith('/api/v1/economic-news/live')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'live_updates': <dynamic>[]},
      };
    }
    return <String, dynamic>{
      'data': <String, dynamic>{
        'events': <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': 'event-1',
            'title': 'US CPI',
            'currency': 'USD',
            'impact': 'HIGH',
            'forecast': '2.8%',
            'previous': '2.7%',
            'scheduled_at_utc': '2026-10-21T12:30:00Z',
          },
        ],
      },
    };
  }
}
