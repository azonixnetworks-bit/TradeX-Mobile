import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/profile/presentation/mobile_number_details_screen.dart';
import 'package:tradex_mobile/features/profile/presentation/trusted_devices_screen.dart';

void main() {
  for (final themeMode in const [ThemeMode.light, ThemeMode.dark]) {
    for (final width in const [360.0, 390.0, 430.0]) {
      testWidgets(
        'mobile number details fits ${width.toInt()} px in ${themeMode.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = SecureSessionStore();
          final client = TradeXApiClient(store, DeviceIdentity(store));

          await tester.pumpWidget(
            MaterialApp(
              theme: TradeXTheme.light,
              darkTheme: TradeXTheme.dark,
              themeMode: themeMode,
              home: MobileNumberDetailsScreen(
                apiClient: client,
                number: '+94771234567',
                verified: true,
                telegramUsername: 'tradex_member',
              ),
            ),
          );

          expect(find.text('Mobile Number Details'), findsOneWidget);
          expect(find.text('+94771234567'), findsOneWidget);
          expect(find.text('Verified'), findsOneWidget);
          expect(find.text('WhatsApp'), findsOneWidget);
          expect(find.text('Telegram'), findsOneWidget);
          expect(find.text('@tradex_member'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('trusted devices displays the two-mobile one-desktop policy', (
    tester,
  ) async {
    final store = SecureSessionStore();
    final client = _TrustedDevicesApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(home: TrustedDevicesScreen(apiClient: client)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Android and iOS · up to 2 active devices'),
      findsOneWidget,
    );
    expect(find.text('Customer Phone 1'), findsAtLeastNWidgets(1));
    expect(find.text('Customer Phone 2'), findsAtLeastNWidgets(1));
    final desktopPolicy = find.text(
      'Windows, macOS and Web · up to 1 active device',
    );
    await tester.scrollUntilVisible(
      desktopPolicy,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(desktopPolicy, findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Customer Desktop').first,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Customer Desktop'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}

class _TrustedDevicesApiClient extends TradeXApiClient {
  _TrustedDevicesApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path != '/api/v1/profile/settings/devices') {
      throw StateError('Unexpected GET $path');
    }

    Map<String, dynamic> device(
      String uuid,
      String slot,
      String platform,
      String name,
    ) => <String, dynamic>{
      'uuid': uuid,
      'is_current': uuid == 'mobile-1',
      'slot': slot,
      'platform': platform,
      'device_name': name,
      'device_model': name,
      'os_version': 'Test OS',
      'trusted': true,
      'active': true,
      'registered_at': '2026-10-20T10:00:00Z',
      'last_seen_at': '2026-10-20T10:10:00Z',
      'revoked_at': null,
    };

    return <String, dynamic>{
      'data': <String, dynamic>{
        'items': <Map<String, dynamic>>[
          device('mobile-1', 'MOBILE', 'ANDROID', 'Customer Phone 1'),
          device('mobile-2', 'MOBILE', 'IOS', 'Customer Phone 2'),
          device('desktop-1', 'DESKTOP', 'WINDOWS', 'Customer Desktop'),
        ],
        'policy': <String, dynamic>{
          'maximum_active_mobile_devices': 2,
          'maximum_active_desktop_devices': 1,
        },
      },
    };
  }
}
