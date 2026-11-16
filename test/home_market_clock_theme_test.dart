import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/data/auth_repository.dart';
import 'package:tradex_mobile/features/catalog/catalog_dependencies.dart';
import 'package:tradex_mobile/features/home/home_dependencies.dart';
import 'package:tradex_mobile/features/home/presentation/home_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final isDark in [false, true]) {
    testWidgets(
      '24h clock uses ${isDark ? 'original dark' : 'silver light'} painter',
      (tester) async {
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
        final api = _ClockThemeApiClient(store, device);
        CatalogDependenciesRegistry.configure(CatalogDependencies(api));

        await tester.pumpWidget(
          MaterialApp(
            theme: isDark ? TradeXTheme.dark : TradeXTheme.light,
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
        await tester.pump(const Duration(milliseconds: 300));

        final clock = find.byKey(const ValueKey('market-24h-clock'));
        expect(clock, findsOneWidget);
        final painter = tester.widget<CustomPaint>(clock).painter;
        expect(painter, isNotNull);
        expect(
          painter.runtimeType.toString(),
          isDark ? '_MarketClockDialPainter' : '_LightMarketClockDialPainter',
        );
        expect(find.byKey(const ValueKey('market-session-scroll')), findsOneWidget);
        expect(find.text('World Market Sessions'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _ClockThemeApiClient extends TradeXApiClient {
  _ClockThemeApiClient(super.store, super.identity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/market-clock')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'sessions': <dynamic>[]},
      };
    }
    if (path == '/api/v1/dashboard') {
      return <String, dynamic>{
        'data': <String, dynamic>{'learning': <String, dynamic>{}},
      };
    }
    return <String, dynamic>{'data': <String, dynamic>{}};
  }
}
