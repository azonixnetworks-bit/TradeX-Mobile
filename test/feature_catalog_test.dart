import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/catalog/models/feature_spec.dart';
import 'package:tradex_mobile/features/catalog/presentation/feature_catalog_screen.dart';
import 'package:tradex_mobile/features/catalog/presentation/secure_workflow_screens.dart';
import 'package:tradex_mobile/features/market/presentation/crypto_market_screen.dart';

void main() {
  test('catalog contains every planned missing screen exactly once', () {
    expect(tradeXFeatureSpecs, hasLength(41));
    expect(
      tradeXFeatureSpecs.map((feature) => feature.id).toSet(),
      hasLength(41),
    );
  });

  test('backend-backed features use versioned mobile API routes', () {
    final backed = tradeXFeatureSpecs.where(
      (feature) => feature.endpoint != null,
    );
    expect(backed, isNotEmpty);
    for (final feature in backed) {
      expect(feature.endpoint, startsWith('/api/v1/'), reason: feature.title);
    }
  });

  test('unsupported support screens are explicitly local', () {
    expect(featureById('help-faq').kind, FeatureKind.local);
    expect(featureById('contact-support').kind, FeatureKind.local);
    expect(featureById('help-faq').endpoint, isNull);
    expect(featureById('contact-support').endpoint, isNull);
  });

  for (final width in const [360.0, 390.0, 430.0]) {
    testWidgets('service catalog lays out at ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = SecureSessionStore();
      final client = TradeXApiClient(store, DeviceIdentity(store));
      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: FeatureCatalogScreen(apiClient: client),
        ),
      );
      expect(find.text('TradeX Services'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('secure workflows render without exposing fake success', (
    tester,
  ) async {
    final store = SecureSessionStore();
    final client = TradeXApiClient(store, DeviceIdentity(store));
    final screens = <(Widget, String)>[
      (KycSubmissionScreen(apiClient: client), 'KYC Document Submission'),
      (PaymentProofScreen(apiClient: client), 'Upload Payment Proof'),
      (ContactChangeScreen(apiClient: client), 'Change Contact'),
      (CopyTradeDashboardScreen(apiClient: client), 'Copy Trading'),
      (BrokerConnectionScreen(apiClient: client), 'Connect Broker Account'),
      (PaymentCheckoutScreen(apiClient: client), 'Payment Checkout'),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(theme: TradeXTheme.dark, home: screen.$1),
      );
      expect(find.text(screen.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('market screener opens the live market screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = _CatalogApiClient();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => openTradeXFeature(
              context,
              client,
              featureById('market-screener'),
            ),
            child: const Text('Open screener'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open screener'));
    await tester.pumpAndSettle();

    expect(find.byType(CryptoMarketScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('prepared bank payment shows backend transfer instructions', (
    tester,
  ) async {
    final store = SecureSessionStore();
    final client = TradeXApiClient(store, DeviceIdentity(store));
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentProofScreen(
          apiClient: client,
          initialOrderUuid: '11111111-1111-4111-8111-111111111111',
          initialEvidenceType: 'bank',
          preparedOrder: const {
            'expires_at': '2099-01-01T00:00:00Z',
            'manual_payment': {
              'type': 'BANK',
              'reference': 'TX-123',
              'bank_name': 'TradeX Bank',
              'branch': 'Colombo',
              'account_holder': 'TradeX',
              'account_number': '1234567890',
              'amount': {'currency': 'LKR', 'amount': '25000.00'},
            },
          },
        ),
      ),
    );
    expect(find.text('Bank transfer details'), findsOneWidget);
    expect(find.text('TradeX Bank'), findsOneWidget);
    expect(find.text('LKR 25000.00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('prepared USDT payment clearly enforces TRC20', (tester) async {
    final store = SecureSessionStore();
    final client = TradeXApiClient(store, DeviceIdentity(store));
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentProofScreen(
          apiClient: client,
          initialOrderUuid: '22222222-2222-4222-8222-222222222222',
          initialEvidenceType: 'usdt',
          preparedOrder: const {
            'expires_at': '2099-01-01T00:00:00Z',
            'manual_payment': {
              'type': 'CRYPTO',
              'reference': 'TX-456',
              'coin_symbol': 'USDT',
              'network': 'TRC20',
              'wallet_address': 'TExampleWalletAddress',
              'amount': {'currency': 'USDT', 'amount': '79.000000'},
            },
          },
        ),
      ),
    );
    expect(find.text('USDT TRC20 deposit details'), findsOneWidget);
    expect(find.text('TExampleWalletAddress'), findsOneWidget);
    expect(
      find.textContaining('Send only USDT using the TRC20 network'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _CatalogApiClient extends TradeXApiClient {
  _CatalogApiClient()
    : super(SecureSessionStore(), DeviceIdentity(SecureSessionStore()));

  @override
  Future<String?> currentAccountStorageKey() async => 'test-account';

  @override
  Future<Map<String, dynamic>> getJson(String path) async => const {
    'data': <String, dynamic>{},
  };
}
