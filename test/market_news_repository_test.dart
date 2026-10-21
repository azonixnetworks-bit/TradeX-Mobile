import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/features/home/data/market_news_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'stores Laravel economic events locally and reuses them all day',
    () async {
      final store = SecureSessionStore();
      final api = _EconomicNewsApiClient(store, DeviceIdentity(store));
      final repository = MarketNewsRepository(api);
      final today = DateTime(2026, 10, 21, 8);

      final first = await repository.today(now: today);
      final second = await repository.today(now: DateTime(2026, 10, 21, 20));

      expect(api.paths, hasLength(1));
      expect(
        api.paths.single,
        startsWith('/api/v1/economic-news/calendar?from='),
      );
      expect(api.paths.single, contains('&to='));
      expect(api.paths.single, endsWith('&per_page=100'));
      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(first.single.title, 'US CPI');
      expect(first.single.source, 'Trading Economics');
      expect(first.single.impact, 'HIGH');
      expect(first.single.bias, 'BEARISH');
      expect(first.single.confidenceScore, 82);
      expect(first.single.affectedPairs, ['EURUSD', 'XAUUSD']);
    },
  );

  test('force refresh loads news published later on the same day', () async {
    final store = SecureSessionStore();
    final api = _PublishLaterApiClient(store, DeviceIdentity(store));
    final repository = MarketNewsRepository(api);
    final now = DateTime(2026, 10, 21, 8);

    expect(await repository.today(now: now), isEmpty);
    expect(await repository.today(now: now), isEmpty);
    expect(api.calls, 1);

    api.published = true;
    final refreshed = await repository.today(now: now, forceRefresh: true);

    expect(api.calls, 2);
    expect(refreshed.single.title, 'Published later');
  });
}

class _PublishLaterApiClient extends TradeXApiClient {
  _PublishLaterApiClient(super.sessionStore, super.deviceIdentity);

  bool published = false;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    calls++;
    return <String, dynamic>{
      'data': <String, dynamic>{
        'events': published
            ? <Map<String, dynamic>>[
                <String, dynamic>{
                  'uuid': 'published-later',
                  'title': 'Published later',
                  'impact': 'HIGH',
                  'status': 'SCHEDULED',
                  'scheduled_at_utc': '2026-10-22T12:30:00Z',
                },
              ]
            : <Map<String, dynamic>>[],
      },
    };
  }
}

class _EconomicNewsApiClient extends TradeXApiClient {
  _EconomicNewsApiClient(super.sessionStore, super.deviceIdentity);

  final List<String> paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    paths.add(path);
    return <String, dynamic>{
      'data': <String, dynamic>{
        'events': <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': 'event-1',
            'title': 'US CPI',
            'currency': 'USD',
            'impact': 'HIGH',
            'bias': 'BEARISH',
            'confidence_score': 82,
            'status': 'SCHEDULED',
            'forecast': '2.8%',
            'previous': '2.7%',
            'scheduled_at_utc': '2026-10-22T12:30:00Z',
            'source': <String, dynamic>{
              'code': 'TE',
              'name': 'Trading Economics',
            },
            'affected_pairs': <Map<String, dynamic>>[
              <String, dynamic>{'symbol': 'EURUSD'},
              <String, dynamic>{'symbol': 'XAUUSD'},
            ],
          },
          <String, dynamic>{
            'uuid': 'expired-event',
            'title': 'Expired release',
            'impact': 'LOW',
            'status': 'SCHEDULED',
            'scheduled_at_utc': '2026-10-20T12:30:00Z',
          },
        ],
      },
    };
  }
}
