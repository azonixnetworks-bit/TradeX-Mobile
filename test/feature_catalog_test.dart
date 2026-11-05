import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/catalog/models/feature_spec.dart';
import 'package:tradex_mobile/features/catalog/presentation/feature_catalog_screen.dart';
import 'package:tradex_mobile/features/catalog/catalog_dependencies.dart';
import 'package:tradex_mobile/features/catalog/presentation/secure_workflow_screens.dart';
import 'package:tradex_mobile/features/market/presentation/crypto_market_screen.dart';

void main() {
  test('catalog contains every planned missing screen exactly once', () {
    expect(tradeXFeatureSpecs, hasLength(42));
    expect(
      tradeXFeatureSpecs.map((feature) => feature.id).toSet(),
      hasLength(42),
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
          home: FeatureCatalogScreen(dependencies: CatalogDependencies(client)),
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
              CatalogDependencies(client),
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

  testWidgets('checkout includes enabled manual bank and USDT accounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentCheckoutScreen(
          apiClient: _ManualPaymentCatalogApiClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Stripe'), findsWidgets);
    expect(find.textContaining('Local bank deposit'), findsOneWidget);
    expect(find.textContaining('USDT manual deposit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout payment method stays responsive on narrow phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentCheckoutScreen(
          apiClient: _ManualPaymentCatalogApiClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment Checkout'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout supports configured legacy bank and USDT methods', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentCheckoutScreen(apiClient: _LegacyManualCatalogApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Local Bank Deposit'), findsOneWidget);
    expect(find.textContaining('USDT TRC20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy bank selection opens secure deposit submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentCheckoutScreen(apiClient: _LegacyManualCatalogApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Local Bank Deposit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Continue with manual payment'));
    await tester.pumpAndSettle();

    expect(find.text('Upload Payment Proof'), findsOneWidget);
    expect(find.text('Bank transfer details'), findsOneWidget);
    expect(find.text('TradeX Local Bank'), findsOneWidget);
    expect(find.textContaining('Payment order UUID'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout never exposes the internal product UUID', (
    tester,
  ) async {
    const productUuid = '123e4567-e89b-42d3-a456-426614174000';
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PaymentCheckoutScreen(
          apiClient: _ManualPaymentCatalogApiClient(),
          productUuid: productUuid,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(productUuid), findsNothing);
    expect(find.textContaining('Product UUID'), findsNothing);
    expect(tester.takeException(), isNull);
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

class _ManualPaymentCatalogApiClient extends _CatalogApiClient {
  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/payments/methods') {
      return const {
        'data': {
          'purchase_allowed': true,
          'product': {
            'name': 'Education Premium',
            'base_price': {'currency': 'USD', 'amount': '79.00'},
          },
          'methods': [
            {
              'code': 'stripe',
              'display_name': 'Stripe',
              'available': true,
              'mode': 'REDIRECT',
              'amount': {'currency': 'USD', 'amount': '79.00'},
            },
          ],
        },
      };
    }
    if (path == '/api/v1/payments/manual-accounts') {
      return const {
        'data': {
          'accounts': [
            {
              'uuid': 'bank-account',
              'type': 'BANK',
              'display_name': 'TradeX local bank',
              'tender': {'currency': 'LKR', 'amount': '25000.00'},
            },
            {
              'uuid': 'usdt-account',
              'type': 'CRYPTO',
              'coin': 'USDT',
              'display_name': 'TradeX USDT TRC20',
              'tender': {'currency': 'USDT', 'amount': '79.00'},
            },
          ],
        },
      };
    }
    return super.getJson(path);
  }
}

class _LegacyManualCatalogApiClient extends _CatalogApiClient {
  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/payments/methods') {
      return const {
        'data': {
          'purchase_allowed': true,
          'product': {
            'name': 'Education Premium',
            'base_price': {'currency': 'USD', 'amount': '79.00'},
          },
          'methods': [
            {
              'code': 'stripe',
              'display_name': 'Stripe',
              'available': true,
              'mode': 'REDIRECT',
              'amount': {'currency': 'USD', 'amount': '79.00'},
            },
            {
              'code': 'LOCAL_BANK',
              'display_name': 'Local Bank Deposit',
              'available': true,
              'mode': 'MANUAL_REVIEW',
              'amount': {'currency': 'LKR', 'amount': '25000.00'},
              'instructions': {
                'bank_name': 'TradeX Local Bank',
                'branch': 'Colombo',
                'account_holder': 'TradeX',
                'account_number': '1234567890',
              },
              'submit_endpoint': 'POST /api/v1/payments/bank-deposits',
            },
            {
              'code': 'USDT_TRC20',
              'display_name': 'USDT TRC20',
              'available': true,
              'mode': 'MANUAL_REVIEW',
              'amount': {'currency': 'USDT', 'amount': '79.000000'},
              'instructions': {
                'token': 'USDT',
                'network': 'TRC20',
                'wallet_address': 'TExampleWalletAddress',
              },
              'submit_endpoint': 'POST /api/v1/payments/usdt-deposits',
            },
          ],
        },
      };
    }
    if (path == '/api/v1/payments/manual-accounts') {
      return const {
        'data': {'accounts': <Map<String, dynamic>>[]},
      };
    }
    return super.getJson(path);
  }
}
