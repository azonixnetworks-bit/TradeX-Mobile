import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/home/data/trade_ideas_repository.dart';
import 'package:tradex_mobile/features/home/presentation/crypto_market_screen.dart';
import 'package:tradex_mobile/features/home/presentation/tradingview_chart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('crypto market filters and local watchlist work', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = SecureSessionStore();
    final api = _CryptoScreenApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(
          apiClient: api,
          tradeIdeasRepository: TradeIdeasRepository(api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crypto Market'), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-live-summary')), findsOneWidget);
    expect(find.text(r'$2.20B'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-filter-gainers')), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-asset-BTCUSDT')), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-asset-DOGEUSDT')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('open-crypto-bubbles')));
    await tester.pumpAndSettle();
    expect(find.text('Bubble Screener'), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-bubble-BTCUSDT')), findsOneWidget);
    Navigator.of(tester.element(find.text('Bubble Screener'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('crypto-filter-gainers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crypto-asset-BTCUSDT')), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-asset-DOGEUSDT')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('crypto-filter-losers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crypto-asset-DOGEUSDT')), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-asset-BTCUSDT')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('crypto-filter-overview')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('crypto-watch-BTCUSDT')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('crypto-market-filters')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('crypto-filter-watchlist')));
    await tester.pumpAndSettle();

    expect(find.text('My Watchlist'), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-asset-BTCUSDT')), findsOneWidget);
    expect(find.byKey(const ValueKey('crypto-asset-ETHUSDT')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('crypto-watch-BTCUSDT')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your watchlist is empty'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('manage-crypto-watchlist')));
    await tester.pumpAndSettle();
    expect(find.text('Manage Watchlist'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('manage-crypto-watch-ETHUSDT')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crypto-asset-ETHUSDT')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('TradingView URL is Binance landscape chart without indicators', () {
    final uri = tradingViewUrlForSymbol('BTC/USDT');

    expect(uri.host, 's.tradingview.com');
    expect(uri.queryParameters['symbol'], 'BINANCE:BTCUSDT');
    expect(uri.queryParameters['hidesidetoolbar'], '1');
    expect(uri.queryParameters['studies'], '[]');
  });
}

class _CryptoScreenApiClient extends TradeXApiClient {
  _CryptoScreenApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/screener/results')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'provider': 'BINANCE',
          'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
          'cache': <String, dynamic>{'stale': false},
          'results': List<Map<String, dynamic>>.generate(6, (index) {
            const symbols = [
              'BTCUSDT',
              'ETHUSDT',
              'SOLUSDT',
              'XRPUSDT',
              'ADAUSDT',
              'DOGEUSDT',
            ];
            final symbol = symbols[index];
            return <String, dynamic>{
              'symbol': symbol,
              'name': symbol,
              'base_currency': symbol.replaceAll('USDT', ''),
              'quote_currency': 'USDT',
              'price': 100 - index,
              'change_percent': index == 5 ? -1.5 : 6 - index,
              'trend': 'BULLISH',
            };
          }),
        },
      };
    }
    if (path.startsWith('/api/v1/screener/bubbles')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'provider': 'BINANCE',
          'source': 'BINANCE_LIVE',
          'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
          'stale': false,
          'summary': <String, dynamic>{
            'total_assets': 6,
            'gainers': 5,
            'losers': 1,
            'average_change': 1.8,
            'total_quote_volume': 2200000000,
          },
          'assets': <Map<String, dynamic>>[
            <String, dynamic>{
              'symbol': 'BTCUSDT',
              'base_currency': 'BTC',
              'price': 67842.2,
              'change_percent': 2.48,
              'quote_volume': 2200000000,
            },
          ],
        },
      };
    }
    if (path.startsWith('/api/v1/trade-ideas?')) {
      return <String, dynamic>{
        'data': <String, dynamic>{'trade_ideas': <dynamic>[]},
      };
    }
    throw StateError('Unexpected path: $path');
  }
}
