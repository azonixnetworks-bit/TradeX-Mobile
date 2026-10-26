import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/copy_trading/data/copy_trading_repository.dart';
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
      final repository = CopyTradingRepository(api, intentStore: intents);
      await intents.write('market-1', {
        'onboarding_intent_uuid': 'intent-1',
        'expires_at': '2099-01-01T00:00:00Z',
      });

      final account = await repository.submitBrokerAccount(
        marketId: 'market-1',
        accountNumber: '12345678',
      );

      expect(account['uuid'], 'account-1');
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
      final repository = CopyTradingRepository(
        api,
        intentStore: _MemoryIntentStore(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: CopyTradingHomeScreen(apiClient: api, repository: repository),
        ),
      );
      await pumpNetworkFrame(tester);

      expect(find.text('Official cTrader'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      // Rendering exceptions are surfaced automatically by the test binding.
    },
  );

  testWidgets('all six copy trading screens render real or honest empty data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _FakeCopyTradeApi();
    final repository = CopyTradingRepository(
      api,
      intentStore: _MemoryIntentStore(),
    );
    final screens = <(Widget, String)>[
      (
        CopyTradingHomeScreen(apiClient: api, repository: repository),
        'Official cTrader',
      ),
      (CopyTradingBrokerDirectoryScreen(repository: repository), 'Choose Your'),
      (
        CopyTradingVerificationScreen(
          repository: repository,
          account: _account,
        ),
        'Account',
      ),
      (
        CopyTradingBotActivationScreen(
          repository: repository,
          account: _account,
        ),
        'Bot Activation Unavailable',
      ),
      (
        CopyTradingLiveDashboardScreen(
          repository: repository,
          account: _account,
        ),
        'Live telemetry unavailable',
      ),
      (
        CopyTradingHistorySettingsScreen(
          repository: repository,
          account: _account,
        ),
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
