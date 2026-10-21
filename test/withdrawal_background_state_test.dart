import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/auth_session.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/features/profile/presentation/withdrawal_method_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bank TOTP flow survives app pause and resume', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final sessionStore = SecureSessionStore();
    final now = DateTime.now();
    await sessionStore.writeSession(
      AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: now.add(const Duration(hours: 1)),
        refreshExpiresAt: now.add(const Duration(days: 1)),
        sessionUuid: 'background-test-session',
        user: const {'id': 7},
      ),
    );
    final api = _WithdrawalTestApiClient(sessionStore);

    await tester.pumpWidget(
      MaterialApp(
        home: WithdrawalMethodScreen(
          apiClient: api,
          method: WithdrawalMethod.localBank,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(
      _fieldWithLabel('Customer / Account Holder Name'),
      'Test Customer',
    );
    await tester.enterText(_fieldWithLabel('Bank Name'), 'Bank of Ceylon');
    await tester.enterText(_fieldWithLabel('Bank Branch'), 'Gampaha Branch');
    await tester.enterText(
      _fieldWithLabel('Bank Account Number'),
      '1234567890',
    );
    await tester.enterText(
      _fieldWithLabel('Confirm Bank Account Number'),
      '1234567890',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Security confirmation'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Security confirmation'), findsOneWidget);
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('Bank of Ceylon'), findsOneWidget);
    expect(find.text('Gampaha Branch'), findsOneWidget);
  });

  testWidgets('bank details save disposes autocomplete overlays safely', (
    tester,
  ) async {
    final api = await _createApi('bank-save-test-session');
    await _openWithdrawalRoute(tester, api, WithdrawalMethod.localBank);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(
      _fieldWithLabel('Customer / Account Holder Name'),
      'Test Customer',
    );
    await tester.enterText(_fieldWithLabel('Bank Name'), 'Bank of Ceylon');
    await tester.enterText(_fieldWithLabel('Bank Branch'), 'Gampaha Branch');
    await tester.enterText(
      _fieldWithLabel('Bank Account Number'),
      '1234567890',
    );
    await tester.enterText(
      _fieldWithLabel('Confirm Bank Account Number'),
      '1234567890',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '6-digit authenticator code'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.savedPayload?['bank_name'], 'Bank of Ceylon');
    expect(find.byKey(const ValueKey('profile-host')), findsOneWidget);
    expect(find.text('Local Bank Account details saved securely.'), findsOne);
  });

  for (final scenario
      in <
        ({
          String name,
          WithdrawalMethod method,
          String firstLabel,
          String confirmationLabel,
          String value,
          String payloadKey,
        })
      >[
        (
          name: 'PayPal',
          method: WithdrawalMethod.paypal,
          firstLabel: 'PayPal Email Address',
          confirmationLabel: 'Confirm PayPal Email',
          value: 'paypal@example.test',
          payloadKey: 'paypal_email',
        ),
        (
          name: 'Binance',
          method: WithdrawalMethod.binance,
          firstLabel: 'Binance Email Address',
          confirmationLabel: 'Confirm Binance Email',
          value: 'binance@example.test',
          payloadKey: 'binance_email',
        ),
        (
          name: 'USDT TRC20',
          method: WithdrawalMethod.usdtTrc20,
          firstLabel: 'Add New USDT TRC20 Wallet Address',
          confirmationLabel: 'Confirm USDT TRC20 Address',
          value: 'TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE',
          payloadKey: 'usdt_trc20_address',
        ),
      ]) {
    testWidgets('${scenario.name} first-time save returns to profile safely', (
      tester,
    ) async {
      final api = await _createApi('${scenario.name}-first-save');
      await _openWithdrawalRoute(tester, api, scenario.method);

      expect(_fieldWithLabel(scenario.firstLabel), findsOneWidget);
      expect(_fieldWithLabel(scenario.confirmationLabel), findsOneWidget);
      await tester.enterText(
        _fieldWithLabel(scenario.firstLabel),
        scenario.value,
      );
      await tester.enterText(
        _fieldWithLabel(scenario.confirmationLabel),
        scenario.value,
      );
      await _submitFinancialForm(tester, 'Confirm');

      expect(tester.takeException(), isNull);
      expect(api.savedPayload?[scenario.payloadKey], scenario.value);
      expect(find.byKey(const ValueKey('profile-host')), findsOneWidget);
      expect(find.byType(WithdrawalMethodScreen), findsNothing);
    });
  }

  for (final scenario
      in <
        ({
          String name,
          WithdrawalMethod method,
          String updateAction,
          String currentLabel,
          String currentMasked,
          String newLabel,
          String confirmationLabel,
          String newValue,
          String payloadKey,
          String profileKey,
          String maskedKey,
        })
      >[
        (
          name: 'PayPal',
          method: WithdrawalMethod.paypal,
          updateAction: 'Update PayPal Email',
          currentLabel: 'Current PayPal Email',
          currentMasked: 'pa***@example.test',
          newLabel: 'New PayPal Email',
          confirmationLabel: 'Confirm New PayPal Email',
          newValue: 'new-paypal@example.test',
          payloadKey: 'paypal_email',
          profileKey: 'paypal',
          maskedKey: 'email_masked',
        ),
        (
          name: 'Binance',
          method: WithdrawalMethod.binance,
          updateAction: 'Update Binance Email',
          currentLabel: 'Current Binance Email',
          currentMasked: 'bi***@example.test',
          newLabel: 'New Binance Email',
          confirmationLabel: 'Confirm New Binance Email',
          newValue: 'new-binance@example.test',
          payloadKey: 'binance_email',
          profileKey: 'binance',
          maskedKey: 'email_masked',
        ),
        (
          name: 'USDT TRC20',
          method: WithdrawalMethod.usdtTrc20,
          updateAction: 'Update Wallet Address',
          currentLabel: 'Current USDT TRC20 Address',
          currentMasked: 'TQn9Y2...KcbLSE',
          newLabel: 'New USDT TRC20 Address',
          confirmationLabel: 'Confirm New USDT TRC20 Address',
          newValue: 'TYMwiFSfZ4pFGLsFZaG2FtYntDf5Xc9Dfv',
          payloadKey: 'usdt_trc20_address',
          profileKey: 'usdt_trc20',
          maskedKey: 'address_masked',
        ),
      ]) {
    testWidgets('${scenario.name} update shows current and saves new value', (
      tester,
    ) async {
      final api = await _createApi(
        '${scenario.name}-update',
        financial: <String, dynamic>{
          scenario.profileKey: <String, dynamic>{
            'configured': true,
            scenario.maskedKey: scenario.currentMasked,
          },
        },
      );
      await _openWithdrawalRoute(tester, api, scenario.method);

      expect(find.text(scenario.currentMasked), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, scenario.updateAction),
      );
      await tester.pumpAndSettle();
      expect(_fieldWithLabel(scenario.currentLabel), findsOneWidget);
      expect(_fieldWithLabel(scenario.newLabel), findsOneWidget);
      expect(_fieldWithLabel(scenario.confirmationLabel), findsOneWidget);
      await tester.enterText(
        _fieldWithLabel(scenario.newLabel),
        scenario.newValue,
      );
      await tester.enterText(
        _fieldWithLabel(scenario.confirmationLabel),
        scenario.newValue,
      );
      await _submitFinancialForm(tester, 'Update');

      expect(tester.takeException(), isNull);
      expect(api.savedPayload?[scenario.payloadKey], scenario.newValue);
      expect(find.byKey(const ValueKey('profile-host')), findsOneWidget);
      expect(find.byType(WithdrawalMethodScreen), findsNothing);
    });
  }

  testWidgets('configured bank update returns to profile without red screen', (
    tester,
  ) async {
    final api = await _createApi(
      'bank-update',
      financial: <String, dynamic>{
        'bank': <String, dynamic>{
          'configured': true,
          'account_masked': '12****7890',
        },
      },
    );
    await _openWithdrawalRoute(tester, api, WithdrawalMethod.localBank);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Update Bank Details'));
    await tester.pumpAndSettle();

    expect(_fieldWithLabel('Current Bank Account Number'), findsOneWidget);
    await tester.enterText(
      _fieldWithLabel('Customer / Account Holder Name'),
      'Updated Customer',
    );
    await tester.enterText(_fieldWithLabel('Bank Name'), 'Bank of Ceylon');
    await tester.enterText(_fieldWithLabel('Bank Branch'), 'Colombo Branch');
    await tester.enterText(
      _fieldWithLabel('New Bank Account Number'),
      '9876543210',
    );
    await tester.enterText(
      _fieldWithLabel('Confirm New Bank Account Number'),
      '9876543210',
    );
    await _submitFinancialForm(tester, 'Update');

    expect(tester.takeException(), isNull);
    expect(api.savedPayload?['bank_account_number'], '9876543210');
    expect(find.byKey(const ValueKey('profile-host')), findsOneWidget);
    expect(find.byType(WithdrawalMethodScreen), findsNothing);
  });
}

Finder _fieldWithLabel(String label) =>
    find.widgetWithText(TextFormField, label);

Future<_WithdrawalTestApiClient> _createApi(
  String sessionUuid, {
  Map<String, dynamic>? financial,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final sessionStore = SecureSessionStore();
  final now = DateTime.now();
  await sessionStore.writeSession(
    AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessExpiresAt: now.add(const Duration(hours: 1)),
      refreshExpiresAt: now.add(const Duration(days: 1)),
      sessionUuid: sessionUuid,
      user: const {'id': 7},
    ),
  );
  return _WithdrawalTestApiClient(sessionStore, financial: financial);
}

Future<void> _openWithdrawalRoute(
  WidgetTester tester,
  _WithdrawalTestApiClient api,
  WithdrawalMethod method,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const ValueKey('profile-host'),
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      WithdrawalMethodScreen(apiClient: api, method: method),
                ),
              ),
              child: const Text('Open withdrawal method'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('profile-host')));
  await tester.pumpAndSettle();
}

Future<void> _submitFinancialForm(
  WidgetTester tester,
  String buttonLabel,
) async {
  final submit = find.widgetWithText(FilledButton, buttonLabel);
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
  expect(find.text('Security confirmation'), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextField, '6-digit authenticator code'),
    '123456',
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Confirm').last);
  await tester.pumpAndSettle();
}

class _WithdrawalTestApiClient extends TradeXApiClient {
  _WithdrawalTestApiClient(
    SecureSessionStore sessionStore, {
    Map<String, dynamic>? financial,
  }) : financial = financial ?? const <String, dynamic>{},
       super(sessionStore, DeviceIdentity(sessionStore));

  Map<String, dynamic>? savedPayload;
  final Map<String, dynamic> financial;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/profile/settings') {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profile': <String, dynamic>{
            'identity': <String, dynamic>{'country_code': 'LK'},
            'financial': financial,
          },
        },
      };
    }
    if (path == '/api/v1/payouts/methods') {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'code': 'PAYPAL'},
            <String, dynamic>{'code': 'BINANCE'},
            <String, dynamic>{'code': 'USDT_TRC20'},
            <String, dynamic>{'code': 'LOCAL_BANK'},
          ],
        },
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (path == '/api/v1/profile/financial') {
      savedPayload = Map<String, dynamic>.from(body);
      return <String, dynamic>{
        'data': <String, dynamic>{'updated': true},
      };
    }
    throw StateError('Unexpected PATCH $path');
  }
}
