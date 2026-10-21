import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/features/auth/data/auth_repository.dart';
import 'package:tradex_mobile/features/home/data/learning_repository.dart';
import 'package:tradex_mobile/features/home/data/trade_ideas_repository.dart';
import 'package:tradex_mobile/features/home/presentation/home_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile main menus expand and collapse their grouped options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AppPreferences.instance.load();
    await AppPreferences.instance.setDashboardTab(4);
    final store = SecureSessionStore();
    final device = DeviceIdentity(store);
    final api = _ProfileMenuApiClient(store, device);

    await tester.pumpWidget(
      MaterialApp(
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
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('profile-main-account')),
    );

    expect(find.byKey(const ValueKey('profile-main-account')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-main-withdrawal')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile-main-security')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-main-help')), findsOneWidget);
    expect(find.text('Mobile Number'), findsNothing);
    expect(find.text('PayPal'), findsNothing);
    expect(find.text('Authenticator protected'), findsNothing);
    expect(find.text('Support centre'), findsNothing);

    await _openAndVerify(tester, const ValueKey('profile-main-account'), const [
      'profile@example.test',
      'Mobile Number',
      'Learning language',
      'Appearance',
    ]);
    await _openAndVerify(
      tester,
      const ValueKey('profile-main-withdrawal'),
      const ['PayPal', 'Binance', 'USDT TRC20', 'Bank account'],
    );
    await _openAndVerify(
      tester,
      const ValueKey('profile-main-security'),
      const [
        'Authenticator protected',
        'Trusted devices',
        'Fingerprint: Not added',
        'Passcode: Not added',
      ],
    );
    await _openAndVerify(tester, const ValueKey('profile-main-help'), const [
      'Support centre',
      'Sign out',
      'Sign out and forget this device',
      'Sign out from all devices',
    ]);

    expect(tester.takeException(), isNull);
  });
}

Future<void> _openAndVerify(
  WidgetTester tester,
  Key menuKey,
  List<String> expectedOptions,
) async {
  final menu = find.byKey(menuKey);
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: menu,
      matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
    ),
    findsOneWidget,
  );
  for (final option in expectedOptions) {
    expect(find.text(option), findsAtLeastNWidgets(1));
  }
  await tester.tap(menu);
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: menu,
      matching: find.byIcon(Icons.chevron_right_rounded),
    ),
    findsOneWidget,
  );
  for (final option in expectedOptions.skip(1)) {
    expect(find.text(option), findsNothing);
  }
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .toList();
  fail('Profile menu did not load. Visible text: $visibleText');
}

class _ProfileMenuApiClient extends TradeXApiClient {
  _ProfileMenuApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/dashboard') {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'account': <String, dynamic>{'premium_access': true},
        },
      };
    }
    if (path == '/api/v1/profile/settings') {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profile': <String, dynamic>{
            'identity': <String, dynamic>{
              'name': 'Profile Tester',
              'email': 'profile@example.test',
              'country_code': 'LK',
              'account_type': 'PREMIUM',
              'referral_code': 'TEST123',
            },
            'contact': <String, dynamic>{
              'whatsapp_number': '+94771234567',
              'whatsapp_verified': true,
              'telegram_username': 'profile_test',
            },
            'preferences': <String, dynamic>{'language_code': 'en'},
            'security': <String, dynamic>{'totp_confirmed': true},
            'financial': <String, dynamic>{
              'paypal': <String, dynamic>{
                'configured': false,
                'email_masked': null,
              },
              'binance': <String, dynamic>{
                'configured': false,
                'email_masked': null,
              },
              'usdt_trc20': <String, dynamic>{
                'configured': false,
                'address_masked': null,
              },
              'bank': <String, dynamic>{
                'configured': false,
                'account_masked': null,
              },
            },
          },
          'account_security': <String, dynamic>{
            'verification': <String, dynamic>{'email_verified': true},
          },
        },
      };
    }
    throw StateError('Unexpected GET $path');
  }
}
