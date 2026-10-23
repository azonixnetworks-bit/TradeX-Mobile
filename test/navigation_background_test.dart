import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/auth_session.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/profile/pending_financial_form_store.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/data/auth_repository.dart';
import 'package:tradex_mobile/features/home/data/learning_repository.dart';
import 'package:tradex_mobile/features/home/data/trade_ideas_repository.dart';
import 'package:tradex_mobile/features/home/presentation/home_dashboard_screen.dart';
import 'package:tradex_mobile/features/profile/presentation/withdrawal_method_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final theme in <ThemeData>[TradeXTheme.light, TradeXTheme.dark]) {
    testWidgets(
      'dashboard navigation has no outline in ${theme.brightness.name} mode',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await AppPreferences.instance.load();
        final store = SecureSessionStore();
        final device = DeviceIdentity(store);
        final api = TradeXApiClient(store, device);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
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

        final surface = tester.widget<Container>(
          find.byKey(const ValueKey('dashboard-nav-surface')),
        );
        final decoration = surface.decoration! as BoxDecoration;
        expect(decoration.border, isNull);
        expect(
          find.byKey(const ValueKey('dashboard-nav-selected-0')),
          findsOneWidget,
        );
        final nav = find.byKey(const ValueKey('dashboard-nav-root'));
        expect(
          find.descendant(of: nav, matching: find.text('Home')),
          findsOneWidget,
        );
        for (final label in const [
          'Learn',
          'Trade Ideas',
          'Affiliate',
          'Profile',
        ]) {
          expect(
            find.descendant(of: nav, matching: find.text(label)),
            findsNothing,
          );
        }
      },
    );
  }

  testWidgets('rapid tab changes paint only the selected dashboard screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    final store = SecureSessionStore();
    final device = DeviceIdentity(store);
    final api = TradeXApiClient(store, device);

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

    expect(find.byKey(const PageStorageKey('home-tab')), findsOneWidget);
    expect(find.byKey(const PageStorageKey('profile-tab')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard-nav-item-4')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(const PageStorageKey('profile-tab')), findsOneWidget);
    expect(find.byKey(const PageStorageKey('home-tab')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard-nav-item-3')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(const PageStorageKey('affiliate-tab')), findsOneWidget);
    expect(find.byKey(const PageStorageKey('profile-tab')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard-nav-item-2')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(const PageStorageKey('ideas-tab')), findsOneWidget);
    expect(find.byKey(const PageStorageKey('affiliate-tab')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard-nav-item-0')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(const PageStorageKey('home-tab')), findsOneWidget);
    expect(find.byKey(const PageStorageKey('ideas-tab')), findsNothing);
  });

  testWidgets('horizontal swipes move to next and previous dashboard tabs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    final store = SecureSessionStore();
    final device = DeviceIdentity(store);
    final api = TradeXApiClient(store, device);

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

    // Start outside horizontally scrollable home carousels so this gesture
    // represents the dashboard-level page swipe.
    await tester.dragFrom(const Offset(350, 350), const Offset(-220, 0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const PageStorageKey('learn-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-nav-label-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-nav-label-0')), findsNothing);

    await tester.drag(
      find.byKey(const PageStorageKey('learn-tab')),
      const Offset(220, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const PageStorageKey('home-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-nav-label-0')), findsOneWidget);
  });

  testWidgets('nested back pops route and root back backgrounds Android task', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'tradex.dashboard.selected_tab': 3,
    });
    await AppPreferences.instance.load();
    final store = SecureSessionStore();
    final device = DeviceIdentity(store);
    final api = TradeXApiClient(store, device);
    final calls = <MethodCall>[];
    const channel = MethodChannel(
      'com.azonixnetworks.tradex_mobile/app_lifecycle',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

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
    expect(
      find.byKey(const ValueKey('dashboard-nav-selected-3')),
      findsOneWidget,
    );

    Navigator.of(tester.element(find.byType(HomeDashboardScreen))).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Nested route')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final nestedNavigator = Navigator.of(
      tester.element(find.text('Nested route')),
    );
    expect(nestedNavigator.canPop(), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Nested route'), findsNothing);
    expect(calls, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(calls.map((call) => call.method), contains('moveTaskToBack'));
    expect(AppPreferences.instance.dashboardTab, 3);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('restores a pending bank verification route after recreation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AppPreferences.instance.load();
    final store = SecureSessionStore();
    final now = DateTime.now();
    await store.writeSession(
      AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: now.add(const Duration(hours: 1)),
        refreshExpiresAt: now.add(const Duration(days: 1)),
        sessionUuid: 'route-restoration-session',
        user: const {'id': 7},
      ),
    );
    await PendingFinancialFormStore().writeWithdrawal(
      PendingFinancialFormDraft(
        method: 'localBank',
        accountHolder: 'Test Customer',
        bankName: 'Bank of Ceylon',
        bankBranch: 'Gampaha Branch',
        accountNumber: '1234567890',
        accountNumberConfirmation: '1234567890',
        awaitingTotp: true,
        updatedAt: now,
      ),
    );
    final device = DeviceIdentity(store);
    final api = TradeXApiClient(store, device);

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
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(WithdrawalMethodScreen), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('dashboard-nav-selected-4'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
