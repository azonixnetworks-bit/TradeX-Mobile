import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/copy_trading/copy_trading_dependencies.dart';
import 'package:tradex_mobile/features/copy_trading/data/datasources/copy_trading_intent_store.dart';
import 'package:tradex_mobile/features/copy_trading/data/models/copy_trading_models.dart';
import 'package:tradex_mobile/features/copy_trading/domain/usecases/copy_trading_use_cases.dart';
import 'package:tradex_mobile/features/copy_trading/presentation/copy_trading_module.dart';

class _FakeCopyTradeApi extends TradeXApiClient {
  _FakeCopyTradeApi()
    : super(SecureSessionStore(), DeviceIdentity(SecureSessionStore()));

  final requests = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    requests.add('GET $path');
    if (path.endsWith('/activation')) {
      return {
        'data': {
          'activation': {
            'state': 'VERIFIED_PENDING_GATES',
            'copy_trade_ready': false,
          },
        },
      };
    }
    if (path.endsWith('/brokers')) {
      return {
        'data': {'brokers': _brokers},
      };
    }
    return {
      'data': {
        'next_step': 'WAITING_FOR_VERIFICATION',
        'copy_trade_ready': false,
        'education_premium': {'active': true},
        'brokers': _brokers,
        'broker_accounts': [_account],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    requests.add('POST $path');
    return {
      'data': {'broker_account': _account},
    };
  }

  @override
  Future<Uint8List> getBytes(String path) async => Uint8List(0);
}

class _MemoryIntentStore implements CopyTradingIntentStore {
  final values = <String, CopyTradeJson>{};

  @override
  Future<void> delete(String marketId) async => values.remove(marketId);

  @override
  Future<CopyTradeJson?> read(String marketId) async => values[marketId];

  @override
  Future<void> write(String marketId, CopyTradeJson value) async {
    values[marketId] = value;
  }
}

const _brokers = <CopyTradeJson>[
  {
    'broker_uuid': 'broker-1',
    'broker_name': 'IC Markets',
    'broker_market_uuid': 'market-1',
    'market_category': 'FOREX',
    'required_currency': 'USD',
  },
  {
    'broker_uuid': 'broker-2',
    'broker_name': 'Binance',
    'broker_market_uuid': 'market-2',
    'market_category': 'CRYPTO',
    'required_currency': 'USDT',
  },
];

const _account = <String, dynamic>{
  'uuid': 'account-1',
  'broker': {'name': 'IC Markets'},
  'market_category': 'FOREX',
  'account_number_masked': '••••4821',
  'status': 'PENDING',
  'activation_state': 'NOT_ELIGIBLE',
};

void main() {
  Future<void> pumpNetworkFrame(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  test(
    'account submission uses and clears the persisted onboarding intent',
    () async {
      final api = _FakeCopyTradeApi();
      final intents = _MemoryIntentStore();
      final useCases = CopyTradingDependencies(
        api,
        intentStore: intents,
      ).useCases;
      await intents.write('market-1', {
        'onboarding_intent_uuid': 'intent-1',
        'expires_at': '2099-01-01T00:00:00Z',
      });

      final account = await useCases.submitBrokerAccount(
        const SubmitCopyTradingAccountParams(
          marketId: 'market-1',
          accountNumber: '12345678',
        ),
      );

      expect(account.uuid, 'account-1');
      expect(api.requests, contains('POST /api/v1/copy-trade/broker-accounts'));
      expect(await intents.read('market-1'), isNull);
    },
  );

  testWidgets(
    'copy trading home is responsive and has no nested navigation bars',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _FakeCopyTradeApi();
      final useCases = CopyTradingDependencies(
        api,
        intentStore: _MemoryIntentStore(),
      ).useCases;

      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: CopyTradingHomeScreen(useCases: useCases),
        ),
      );
      await pumpNetworkFrame(tester);

      expect(find.text('Official cTrader'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      // Rendering exceptions are surfaced automatically by the test binding.
    },
  );

  testWidgets('copy trading home uses readable global light-theme colors', (
    tester,
  ) async {
    final useCases = CopyTradingDependencies(
      _FakeCopyTradeApi(),
      intentStore: _MemoryIntentStore(),
    ).useCases;

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: CopyTradingHomeScreen(useCases: useCases),
      ),
    );
    await pumpNetworkFrame(tester);

    final heading = tester.widget<Text>(find.text('Official cTrader'));
    final subtitle = tester.widget<Text>(
      find.text('Manage verified copy trading accounts securely.'),
    );
    expect(heading.style?.color, const Color(0xFF101828));
    expect(subtitle.style?.color, const Color(0xFF5D6878));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all six copy trading screens render real or honest empty data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _FakeCopyTradeApi();
    final useCases = CopyTradingDependencies(
      api,
      intentStore: _MemoryIntentStore(),
    ).useCases;
    final account = CopyTradingAccountModel.fromJson(_account).toEntity();
    final screens = <(Widget, String)>[
      (CopyTradingHomeScreen(useCases: useCases), 'Official cTrader'),
      (CopyTradingBrokerDirectoryScreen(useCases: useCases), 'Choose Your'),
      (
        CopyTradingVerificationScreen(useCases: useCases, account: account),
        'Account',
      ),
      (
        CopyTradingBotActivationScreen(useCases: useCases, account: account),
        'Bot Activation Unavailable',
      ),
      (
        CopyTradingLiveDashboardScreen(useCases: useCases, account: account),
        'Live telemetry unavailable',
      ),
      (
        CopyTradingHistorySettingsScreen(useCases: useCases, account: account),
        'Trade history unavailable',
      ),
    ];

    for (final item in screens) {
      await tester.pumpWidget(
        MaterialApp(theme: TradeXTheme.dark, home: item.$1),
      );
      await pumpNetworkFrame(tester);
      expect(find.text(item.$2), findsWidgets);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      // Rendering exceptions are surfaced automatically by the test binding.
    }
  });
}
