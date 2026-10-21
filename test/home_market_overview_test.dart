import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/data/auth_repository.dart';
import 'package:tradex_mobile/features/home/data/learning_repository.dart';
import 'package:tradex_mobile/features/home/data/trade_ideas_repository.dart';
import 'package:tradex_mobile/features/home/presentation/home_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home shows four digital market clocks and Laravel news', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'tradex.dashboard.selected_tab': 0,
    });
    await AppPreferences.instance.load();
    final store = SecureSessionStore();
    final device = DeviceIdentity(store);
    final api = _HomeMarketApiClient(store, device);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: HomeDashboardScreen(
          onLogout: () async {},
          onForgetDevice: () async {},
          onLogoutAll: () async {},
          apiClient: api,
          tradeIdeasRepository: TradeIdeasRepository(api),
          learningRepository: LearningRepository(api),
          authRepository: AuthRepository(api, store, device),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('world-market-sessions')), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('New York'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Sydney'), findsOneWidget);
    expect(find.text('Device Time'), findsNothing);
    expect(find.byKey(const ValueKey('market-news-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-news-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-news-card-3')), findsOneWidget);
    expect(find.text('Federal Reserve holds rates steady'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _HomeMarketApiClient extends TradeXApiClient {
  _HomeMarketApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/economic-news/live')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'live_updates': <Map<String, dynamic>>[
            <String, dynamic>{
              'uuid': 'update-1',
              'event_uuid': 'event-1',
              'event_title': 'Federal Reserve holds rates steady',
              'message': 'Policy decision published with updated guidance.',
              'impact': 'HIGH',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'EURUSD'},
              ],
              'published_at_utc': '2026-10-20T09:00:00Z',
            },
            <String, dynamic>{
              'uuid': 'update-2',
              'event_uuid': 'event-2',
              'event_title': 'Gold extends gains',
              'message': 'Bullion moves after the latest macro release.',
              'impact': 'MEDIUM',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'XAUUSD'},
              ],
              'published_at_utc': '2026-10-20T08:45:00Z',
            },
            <String, dynamic>{
              'uuid': 'update-3',
              'event_uuid': 'event-3',
              'event_title': 'Bitcoin reacts to market volatility',
              'message': 'Crypto markets respond to changing risk appetite.',
              'impact': 'LOW',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'BTCUSD'},
              ],
              'published_at_utc': '2026-10-20T08:30:00Z',
            },
            <String, dynamic>{
              'uuid': 'update-4',
              'event_uuid': 'event-4',
              'event_title': 'Oil rises after inventory report',
              'message': 'Energy markets respond to the latest stock data.',
              'impact': 'MEDIUM',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'WTIUSD'},
              ],
              'published_at_utc': '2026-10-20T08:15:00Z',
            },
          ],
        },
      };
    }
    if (path.startsWith('/api/v1/market-clock')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'sessions': <dynamic>[]},
      };
    }
    if (path.startsWith('/api/v1/trade-ideas')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'trade_ideas': <dynamic>[]},
      };
    }
    if (path == '/api/v1/dashboard') {
      return <String, dynamic>{
        'data': <String, dynamic>{'learning': <String, dynamic>{}},
      };
    }
    if (path.startsWith('/api/v1/our-channel/videos')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'videos': <dynamic>[]},
      };
    }
    return <String, dynamic>{'data': <String, dynamic>{}};
  }
}
