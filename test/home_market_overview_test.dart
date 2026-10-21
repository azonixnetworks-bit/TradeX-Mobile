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
    expect(find.byKey(const ValueKey('market-24h-clock')), findsOneWidget);
    final marketClockSize = tester.getSize(
      find.byKey(const ValueKey('market-24h-clock')),
    );
    expect(marketClockSize.width, greaterThan(300));
    expect(marketClockSize.width, lessThanOrEqualTo(450));
    expect(marketClockSize.height, marketClockSize.width);
    expect(find.byKey(const ValueKey('market-session-scroll')), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('New York'), findsOneWidget);
    expect(find.text('Device Time'), findsNothing);
    expect(
      find.byKey(const ValueKey('market-session-art-London')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('market-session-scroll')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Sydney'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-session-art-Sydney')),
      findsOneWidget,
    );
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
    if (path.startsWith('/api/v1/economic-news/events')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'events': <Map<String, dynamic>>[
            <String, dynamic>{
              'uuid': 'event-1',
              'title': 'Federal Reserve holds rates steady',
              'impact': 'HIGH',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'EURUSD'},
              ],
              'scheduled_at_utc': '2026-10-21T09:00:00Z',
            },
            <String, dynamic>{
              'uuid': 'event-2',
              'title': 'Gold extends gains',
              'impact': 'MEDIUM',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'XAUUSD'},
              ],
              'scheduled_at_utc': '2026-10-21T08:45:00Z',
            },
            <String, dynamic>{
              'uuid': 'event-3',
              'title': 'Bitcoin reacts to market volatility',
              'impact': 'LOW',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'BTCUSD'},
              ],
              'scheduled_at_utc': '2026-10-21T08:30:00Z',
            },
            <String, dynamic>{
              'uuid': 'event-4',
              'title': 'Oil rises after inventory report',
              'impact': 'MEDIUM',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'WTIUSD'},
              ],
              'scheduled_at_utc': '2026-10-21T08:15:00Z',
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
