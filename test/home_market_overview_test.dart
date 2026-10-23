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
import 'package:tradex_mobile/features/journal/presentation/trade_journal_home_screen.dart';

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

    expect(find.byKey(const ValueKey('home-services-grid')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-service-trade-journal')),
      findsOneWidget,
    );
    expect(find.text('Trade Journal'), findsOneWidget);
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
      find.byType(CustomScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('economic-news-title')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('market-news-section')), findsOneWidget);
    expect(find.text('Economic News'), findsOneWidget);
    expect(find.byKey(const ValueKey('market-news-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-news-card-3')), findsOneWidget);
    expect(find.text('Federal Reserve holds rates steady'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-news-values-event-1')),
      findsOneWidget,
    );
    expect(find.text('Previous'), findsWidgets);
    expect(find.text('Forecast'), findsWidgets);
    expect(find.text('Actual'), findsWidgets);
    expect(find.text('5.25%'), findsWidgets);
    expect(find.text('5.50%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home trade journal service card opens the journal', (
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
    await tester.tap(find.byKey(const ValueKey('home-service-trade-journal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TradeJournalHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _HomeMarketApiClient extends TradeXApiClient {
  _HomeMarketApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/economic-news/calendar')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'events': <Map<String, dynamic>>[
            <String, dynamic>{
              'uuid': 'event-1',
              'title': 'Federal Reserve holds rates steady',
              'impact': 'HIGH',
              'currency': 'USD',
              'previous': '5.50%',
              'forecast': '5.25%',
              'actual': '5.25%',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'EURUSD'},
              ],
              'scheduled_at_utc': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 4))
                  .toIso8601String(),
            },
            <String, dynamic>{
              'uuid': 'event-2',
              'title': 'Gold extends gains',
              'impact': 'MEDIUM',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'XAUUSD'},
              ],
              'scheduled_at_utc': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 3))
                  .toIso8601String(),
            },
            <String, dynamic>{
              'uuid': 'event-3',
              'title': 'Bitcoin reacts to market volatility',
              'impact': 'LOW',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'BTCUSD'},
              ],
              'scheduled_at_utc': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 2))
                  .toIso8601String(),
            },
            <String, dynamic>{
              'uuid': 'event-4',
              'title': 'Oil rises after inventory report',
              'impact': 'MEDIUM',
              'affected_pairs': <Map<String, dynamic>>[
                <String, dynamic>{'symbol': 'WTIUSD'},
              ],
              'scheduled_at_utc': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 1))
                  .toIso8601String(),
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
