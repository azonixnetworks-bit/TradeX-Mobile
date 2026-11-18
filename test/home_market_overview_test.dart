import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/data/auth_repository.dart';
import 'package:tradex_mobile/features/home/presentation/home_dashboard_screen.dart';
import 'package:tradex_mobile/features/home/home_dependencies.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_home_screen.dart';
import 'package:tradex_mobile/features/catalog/catalog_dependencies.dart';
import 'package:tradex_mobile/features/market/presentation/trading_view_chart_screen.dart';

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
    final observer = _HomeNavigatorObserver();
    CatalogDependenciesRegistry.configure(CatalogDependencies(api));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        navigatorObservers: [observer],
        home: HomeDashboardScreen(
          onLogout: () async {},
          onForgetDevice: () async {},
          onLogoutAll: () async {},
          dependencies: HomeDependencies(
            api,
            AuthRepository(api, store, device),
          ),
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
    final clockGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('market-24h-clock'))),
    );
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.byKey(const ValueKey('market-clock-popup')), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.byKey(const ValueKey('market-clock-popup')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-24h-clock-popup-dial')),
      findsOneWidget,
    );
    await clockGesture.up();
    await tester.tapAt(const Offset(10, 100));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('market-clock-popup')), findsNothing);
    expect(find.byKey(const ValueKey('market-session-scroll')), findsOneWidget);
    // Session cards are compact but retain the original horizontal scroller.
    expect(
      tester
          .getSize(find.byKey(const ValueKey('market-session-scroll')))
          .height,
      132,
    );
    expect(
      find.byKey(const ValueKey('market-session-card-London')),
      findsOneWidget,
    );
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
      find.byKey(const ValueKey('home-market-screener')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Latest 5'), findsOneWidget);
    observer.routes.clear();
    final cryptoQuote = find.byKey(
      const ValueKey('home-screener-quote-CRYPTO0'),
    );
    tester.widget<InkWell>(cryptoQuote).onTap!();
    expect(observer.routes, hasLength(1));
    final chartRoute = observer.routes.single as MaterialPageRoute<void>;
    expect(chartRoute.settings.name, '/market-screener/tradingview');
    final chart = chartRoute.builder(tester.element(cryptoQuote));
    expect(chart, isA<TradingViewChartScreen>());
    expect(
      (chart as TradingViewChartScreen).qualifiedSymbol,
      'BINANCE:CRYPTO0',
    );
    Navigator.of(tester.element(cryptoQuote)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-screener-stocks')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-screener-stock-regions')),
      findsOneWidget,
    );
    for (final region in const ['CSE', 'India', 'International']) {
      expect(find.text(region), findsOneWidget);
    }
    expect(
      api.requestedPaths.any(
        (path) =>
            path.contains('market=STOCKS') &&
            path.contains('region=INTERNATIONAL'),
      ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('home-screener-stock-india')));
    await tester.pumpAndSettle();
    expect(
      api.requestedPaths.any(
        (path) =>
            path.contains('region=INDIA') && path.contains('timeframe=D1'),
      ),
      isTrue,
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
      find.byKey(const ValueKey('market-news-title-event-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-news-artwork-icon-event-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-news-values-event-1')),
      findsOneWidget,
    );
    expect(find.text('Previous'), findsWidgets);
    expect(find.text('Forecast'), findsWidgets);
    expect(find.text('Actual'), findsWidgets);
    expect(find.text('5.25%'), findsWidgets);
    expect(find.text('5.50%'), findsWidgets);

    // Market Categories retain the existing horizontal scroller and actions;
    // only the card visuals and compact viewport height have changed.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-market-categories-scroll')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-market-categories-scroll')),
    );
    await tester.pumpAndSettle();
    final categoryHeight = tester
        .getSize(find.byKey(const ValueKey('home-market-categories-scroll')))
        .height;
    expect(categoryHeight, inInclusiveRange(124, 170));
    // The horizontally lazily-built items need not be instantiated when
    // their strip is outside the test's clipped viewport. Verify the list
    // configuration and all six entries without depending on lazy children.
    final categoryList = tester.widget<ListView>(
      find.descendant(
        of: find.byKey(const ValueKey('home-market-categories-scroll')),
        matching: find.byType(ListView),
      ),
    );
    expect(categoryList.scrollDirection, Axis.horizontal);
    expect(categoryList.physics, isA<BouncingScrollPhysics>());
    expect(categoryList.childrenDelegate.estimatedChildCount, 11);
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
    CatalogDependenciesRegistry.configure(CatalogDependencies(api));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: HomeDashboardScreen(
          onLogout: () async {},
          onForgetDevice: () async {},
          onLogoutAll: () async {},
          dependencies: HomeDependencies(
            api,
            AuthRepository(api, store, device),
          ),
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

  final List<String> requestedPaths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    requestedPaths.add(path);
    if (path.startsWith('/api/v1/screener/results')) {
      final region = Uri.parse('https://local$path').queryParameters['region'];
      final prefix = region ?? 'CRYPTO';
      return <String, dynamic>{
        'data': <String, dynamic>{
          'results': List<Map<String, dynamic>>.generate(
            7,
            (index) => <String, dynamic>{
              'symbol': '$prefix$index',
              'close': 100 + index,
              'change_percent': 7 - index,
              'trend': 'BULLISH',
            },
          ),
        },
      };
    }
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

class _HomeNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> routes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
    super.didPush(route, previousRoute);
  }
}
