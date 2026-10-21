import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/auth_session.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/features/auth/data/auth_repository.dart';
import 'package:tradex_mobile/features/auth/data/password_recovery_repository.dart';
import 'package:tradex_mobile/features/auth/data/registration_repository.dart';
import 'package:tradex_mobile/features/auth/presentation/login_screen.dart';
import 'package:tradex_mobile/features/auth/presentation/quick_unlock_screen.dart';
import 'package:tradex_mobile/features/auth/presentation/session_gate.dart';
import 'package:tradex_mobile/features/home/data/learning_repository.dart';
import 'package:tradex_mobile/features/home/data/trade_ideas_repository.dart';
import 'package:tradex_mobile/features/home/presentation/home_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'process recreation inside lock grace restores the dashboard directly',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await AppPreferences.instance.load();
      final now = DateTime(2026, 10, 20, 15, 35);
      await AppPreferences.instance.setDashboardTab(3);
      await AppPreferences.instance.setQuickUnlockBackgroundLockSeconds(1800);
      await AppPreferences.instance.markBackgrounded(
        now.subtract(const Duration(minutes: 29, seconds: 59)),
      );

      final store = SecureSessionStore();
      final session = _session(now, 'cold-resume-session');
      await store.writeSession(session);
      final device = DeviceIdentity(store);
      final api = _LifecycleApiClient(store, device);
      final auth = _ColdResumeAuthRepository(
        api,
        store,
        device,
        _quickUnlockConfig,
        session,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionGate(
            authRepository: auth,
            registrationRepository: RegistrationRepository(api),
            passwordRecoveryRepository: PasswordRecoveryRepository(api),
            apiClient: api,
            tradeIdeasRepository: TradeIdeasRepository(api),
            learningRepository: LearningRepository(api),
            now: () => now,
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('authenticated-dashboard')),
      );

      expect(auth.restoreCount, 1);
      expect(find.byType(LoginScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('dashboard-nav-selected-3')),
        findsOneWidget,
      );
      expect(AppPreferences.instance.lastBackgroundedAt, isNull);
    },
  );

  testWidgets(
    'process recreation after lock threshold skips splash and requires unlock',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await AppPreferences.instance.load();
      final now = DateTime(2026, 10, 20, 15, 36);
      await AppPreferences.instance.setQuickUnlockBackgroundLockSeconds(1800);
      await AppPreferences.instance.markBackgrounded(
        now.subtract(const Duration(minutes: 30, seconds: 1)),
      );

      final store = SecureSessionStore();
      final session = _session(now, 'cold-locked-session');
      await store.writeSession(session);
      final device = DeviceIdentity(store);
      final api = _LifecycleApiClient(store, device);
      final auth = _ColdResumeAuthRepository(
        api,
        store,
        device,
        _quickUnlockConfig,
        session,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionGate(
            authRepository: auth,
            registrationRepository: RegistrationRepository(api),
            passwordRecoveryRepository: PasswordRecoveryRepository(api),
            apiClient: api,
            tradeIdeasRepository: TradeIdeasRepository(api),
            learningRepository: LearningRepository(api),
            now: () => now,
          ),
        ),
      );
      await _pumpUntilFound(tester, find.byType(LoginScreen));

      expect(auth.restoreCount, 0);
      expect(find.text('The OS for Every Trader'), findsNothing);
      expect(find.text('Enter passcode'), findsOneWidget);
    },
  );

  testWidgets(
    'quick unlock overlays and preserves tab, dashboard, and nested routes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await AppPreferences.instance.load();

      final store = SecureSessionStore();
      const config = QuickUnlockConfig(
        method: 'PIN',
        email: 'trader@example.test',
        credentialId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        pinSalt: 'test-salt',
        pinHash: 'test-hash',
      );
      final now = DateTime(2026, 10, 20, 12);
      var clock = now;
      final session = AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: now.add(const Duration(minutes: 15)),
        refreshExpiresAt: now.add(const Duration(days: 30)),
        sessionUuid: 'lifecycle-session',
        user: const <String, dynamic>{'id': 7, 'email': 'trader@example.test'},
      );
      await store.writeSession(session);
      final device = DeviceIdentity(store);
      final api = _LifecycleApiClient(store, device);
      final auth = _LifecycleAuthRepository(
        api,
        store,
        device,
        config,
        session,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionGate(
            authRepository: auth,
            registrationRepository: RegistrationRepository(api),
            passwordRecoveryRepository: PasswordRecoveryRepository(api),
            apiClient: api,
            tradeIdeasRepository: TradeIdeasRepository(api),
            learningRepository: LearningRepository(api),
            now: () => clock,
          ),
        ),
      );
      await _pumpUntilFound(tester, find.byType(LoginScreen));
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'trader@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'correct-password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Authenticator Code (6 digits)'),
        '123456',
      );
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('authenticated-dashboard')),
      );

      await tester.tap(find.text('Affiliate'));
      await tester.pump();
      expect(find.byKey(const PageStorageKey('affiliate-tab')), findsOneWidget);
      final originalDashboardState = tester.state(
        find.byType(HomeDashboardScreen),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('session-privacy-shield')),
        findsOneWidget,
      );

      clock = now.add(const Duration(seconds: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(QuickUnlockScreen), findsNothing);
      expect(
        tester.state(find.byType(HomeDashboardScreen)),
        same(originalDashboardState),
      );
      expect(find.byKey(const PageStorageKey('affiliate-tab')), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      clock = now.add(const Duration(minutes: 30, seconds: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(QuickUnlockScreen), findsOneWidget);
      final originalUnlockState = tester.state(find.byType(QuickUnlockScreen));
      expect(
        tester.state(find.byType(HomeDashboardScreen)),
        same(originalDashboardState),
      );
      expect(find.byKey(const PageStorageKey('affiliate-tab')), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('session-privacy-shield')),
        findsNothing,
      );
      expect(
        tester.state(find.byType(QuickUnlockScreen)),
        same(originalUnlockState),
      );
      clock = now.add(const Duration(minutes: 30, seconds: 11));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        tester.state(find.byType(QuickUnlockScreen)),
        same(originalUnlockState),
      );

      await _unlock(tester);
      expect(find.byType(QuickUnlockScreen), findsNothing);
      expect(auth.resumeUnlockCount, 1);
      expect(
        tester.state(find.byType(HomeDashboardScreen)),
        same(originalDashboardState),
      );

      Navigator.of(tester.element(find.byType(HomeDashboardScreen))).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Nested course lesson'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Nested course lesson'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      clock = now.add(const Duration(minutes: 60, seconds: 12));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(QuickUnlockScreen), findsOneWidget);
      expect(find.text('Nested course lesson'), findsOneWidget);
      expect(find.text('Nested course lesson').hitTestable(), findsNothing);

      await _unlock(tester);
      expect(find.byType(QuickUnlockScreen), findsNothing);
      expect(find.text('Nested course lesson'), findsOneWidget);
      expect(auth.resumeUnlockCount, 2);
      expect(
        tester.state(find.byType(HomeDashboardScreen, skipOffstage: false)),
        same(originalDashboardState),
      );
    },
  );
}

const _quickUnlockConfig = QuickUnlockConfig(
  method: 'PIN',
  email: 'trader@example.test',
  credentialId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  pinSalt: 'test-salt',
  pinHash: 'test-hash',
);

AuthSession _session(DateTime now, String uuid) => AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  accessExpiresAt: now.add(const Duration(minutes: 15)),
  refreshExpiresAt: now.add(const Duration(days: 30)),
  sessionUuid: uuid,
  user: const <String, dynamic>{'id': 7, 'email': 'trader@example.test'},
);

Future<void> _unlock(WidgetTester tester) async {
  final screen = tester.widget<QuickUnlockScreen>(
    find.byType(QuickUnlockScreen),
  );
  await screen.onUnlocked();
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(QuickUnlockScreen).evaluate().isEmpty) return;
  }
  fail('Quick Unlock overlay did not close.');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected widget was not found.');
}

class _LifecycleAuthRepository extends AuthRepository {
  _LifecycleAuthRepository(
    super.api,
    super.store,
    super.device,
    this.config,
    this.session,
  );

  final QuickUnlockConfig config;
  final AuthSession session;
  int resumeUnlockCount = 0;
  int _configurationReads = 0;

  @override
  Future<QuickUnlockConfig?> quickUnlockConfiguration() async {
    _configurationReads++;
    return _configurationReads == 1 ? null : config;
  }

  @override
  Future<AuthSession?> restoreRememberedSession() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    String? totpCode,
    String? recoveryCode,
    String? quickUnlockMethod,
    String? quickUnlockPin,
  }) async => session;

  @override
  Future<AuthSession> quickLogin(QuickUnlockConfig config) async => session;

  @override
  Future<AuthSession?> restoreSessionAfterQuickUnlock() async {
    resumeUnlockCount++;
    return session;
  }

  @override
  Future<Map<String, dynamic>> quickUnlockStatus() async => <String, dynamic>{
    'enabled': true,
    'policy': <String, dynamic>{'background_lock_seconds': 1800},
  };

  @override
  Future<bool> hasCompletedFirstLogin() async => true;

  @override
  Future<void> markFirstLoginCompleted() async {}
}

class _ColdResumeAuthRepository extends AuthRepository {
  _ColdResumeAuthRepository(
    super.api,
    super.store,
    super.device,
    this.config,
    this.session,
  );

  final QuickUnlockConfig config;
  final AuthSession session;
  int restoreCount = 0;

  @override
  Future<QuickUnlockConfig?> quickUnlockConfiguration() async => config;

  @override
  Future<AuthSession?> restoreRememberedSession() async {
    restoreCount++;
    return session;
  }

  @override
  Future<Map<String, dynamic>> quickUnlockStatus() async => <String, dynamic>{
    'enabled': true,
    'policy': <String, dynamic>{'background_lock_seconds': 1800},
  };

  @override
  Future<bool> hasCompletedFirstLogin() async => true;
}

class _LifecycleApiClient extends TradeXApiClient {
  _LifecycleApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/market-clock')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'sessions': <dynamic>[]},
      };
    }
    if (path == '/api/v1/payments/activation-status') {
      return <String, dynamic>{
        'data': <String, dynamic>{'premium_active': false},
      };
    }
    if (path == '/api/v1/payments/products') {
      return <String, dynamic>{
        'data': <String, dynamic>{'items': <dynamic>[]},
      };
    }
    if (path == '/api/v1/dashboard') {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'account': <String, dynamic>{'premium_access': false},
          'learning': <String, dynamic>{},
        },
      };
    }
    return <String, dynamic>{'data': <String, dynamic>{}};
  }
}
