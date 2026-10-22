import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/features/home/data/crypto_market_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parses live crypto screener and bubble data', () async {
    final store = SecureSessionStore();
    final api = _CryptoApiClient(store, DeviceIdentity(store));
    final repository = CryptoMarketRepository(api);

    final screener = await repository.screener();
    final bubbles = await repository.bubbles();

    expect(screener.provider, 'BINANCE');
    expect(screener.assets.single.symbol, 'BTCUSDT');
    expect(screener.assets.single.price, 67842.2);
    expect(screener.assets.single.changePercent, 2.48);
    expect(bubbles.summary.totalQuoteVolume, 2200000000);
    expect(bubbles.summary.gainers, 1);
    expect(bubbles.assets.single.baseCurrency, 'BTC');
  });

  test('watchlist additions removals and clear persist locally', () async {
    final store = SecureSessionStore();
    final repository = CryptoMarketRepository(
      _CryptoApiClient(store, DeviceIdentity(store)),
    );

    expect(await repository.watchlist(), isEmpty);
    expect(await repository.toggleWatchlist('btcusdt'), {'BTCUSDT'});
    expect(await repository.toggleWatchlist('ethusdt'), {'BTCUSDT', 'ETHUSDT'});

    final reloaded = CryptoMarketRepository(
      _CryptoApiClient(store, DeviceIdentity(store)),
    );
    expect(await reloaded.watchlist(), {'BTCUSDT', 'ETHUSDT'});
    expect(await reloaded.toggleWatchlist('BTCUSDT'), {'ETHUSDT'});
    await reloaded.clearWatchlist();
    expect(await repository.watchlist(), isEmpty);
  });
}

class _CryptoApiClient extends TradeXApiClient {
  _CryptoApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/screener/results')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'provider': 'BINANCE',
          'generated_at_utc': '2026-10-22T10:00:00Z',
          'cache': <String, dynamic>{'stale': false},
          'results': <Map<String, dynamic>>[
            <String, dynamic>{
              'symbol': 'BTCUSDT',
              'name': 'Bitcoin / Tether',
              'base_currency': 'BTC',
              'quote_currency': 'USDT',
              'price': 67842.2,
              'change_percent': 2.48,
              'trend': 'BULLISH',
              'rsi_14': 62.4,
              'quote_volume': 2200000000,
            },
          ],
        },
      };
    }
    return <String, dynamic>{
      'data': <String, dynamic>{
        'provider': 'BINANCE',
        'source': 'BINANCE_LIVE',
        'generated_at_utc': '2026-10-22T10:00:00Z',
        'stale': false,
        'summary': <String, dynamic>{
          'total_assets': 1,
          'gainers': 1,
          'losers': 0,
          'average_change': 2.48,
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
}
