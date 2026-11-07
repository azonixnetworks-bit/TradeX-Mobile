import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/market_assets/market_asset_cache.dart';
import 'package:tradex_mobile/core/market_assets/market_asset_resolver.dart';

void main() {
  group('MarketAssetResolver', () {
    test('resolves forex and Deriv forex into exact paired flags', () {
      final eurusd = MarketAssetResolver.resolve(
        market: 'FOREX',
        symbol: 'EURUSD',
      );
      final gbpjpy = MarketAssetResolver.resolve(
        market: 'FOREX',
        symbol: 'GBPJPY',
      );
      final usdchf = MarketAssetResolver.resolve(
        market: 'DERIV',
        symbol: 'frxUSDCHF',
      );

      expect(eurusd.baseAsset, endsWith('/eu.png'));
      expect(eurusd.quoteAsset, endsWith('/us.png'));
      expect(gbpjpy.baseAsset, endsWith('/gb.png'));
      expect(gbpjpy.quoteAsset, endsWith('/jp.png'));
      expect(usdchf.baseAsset, endsWith('/us.png'));
      expect(usdchf.quoteAsset, endsWith('/ch.png'));
    });

    test('resolves metals, crypto brand shapes and explicit fallbacks', () {
      final gold = MarketAssetResolver.resolve(
        market: 'FOREX',
        symbol: 'XAUUSD',
      );
      final bitcoin = MarketAssetResolver.resolve(
        market: 'CRYPTO',
        symbol: 'BTCUSDT',
      );
      final altcoin = MarketAssetResolver.resolve(
        market: 'CRYPTO',
        symbol: 'SOLUSDT',
      );
      final ethereum = MarketAssetResolver.resolve(
        market: 'CRYPTO',
        symbol: 'ETHUSD',
      );
      final derivBitcoin = MarketAssetResolver.resolve(
        market: 'DERIV',
        symbol: 'cryBTCUSD',
      );

      expect(gold.baseAsset, endsWith('/gold_xau_bullion.png'));
      expect(gold.quoteAsset, endsWith('/us.png'));
      expect(bitcoin.baseAsset, endsWith('/btc.png'));
      expect(bitcoin.primaryVerified, isTrue);
      expect(bitcoin.quoteAsset, endsWith('/usdt_fallback.png'));
      expect(altcoin.baseAsset, endsWith('/sol_fallback.png'));
      expect(altcoin.primaryVerified, isFalse);
      expect(ethereum.baseAsset, endsWith('/eth.png'));
      expect(ethereum.quoteAsset, endsWith('/us.png'));
      expect(derivBitcoin.baseAsset, endsWith('/btc.png'));
      expect(derivBitcoin.quoteAsset, endsWith('/us.png'));
    });

    test('never assigns country flags to stocks or synthetic indices', () {
      final apple = MarketAssetResolver.resolve(
        market: 'STOCKS',
        symbol: 'NASDAQ:AAPL',
      );
      final synthetic = MarketAssetResolver.resolve(
        market: 'DERIV',
        symbol: 'R_100',
      );
      final volatility = MarketAssetResolver.resolve(
        market: 'DERIV',
        symbol: '1HZ100V',
      );
      final tesla = MarketAssetResolver.resolve(
        market: 'STOCKS',
        symbol: 'NASDAQ:TSLA',
      );

      expect(apple.kind, MarketAssetKind.stock);
      expect(apple.baseAsset, isNull);
      expect(apple.quoteAsset, isNull);
      expect(tesla.primaryAsset, isNull);
      expect(synthetic.kind, MarketAssetKind.synthetic);
      expect(synthetic.primaryAsset, endsWith('/unknown_instrument.png'));
      expect(volatility.primaryAsset, endsWith('/unknown_instrument.png'));
    });
  });

  group('MarketAssetDiskCache', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('tradex-assets-test-');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test(
      'downloads once then returns persistent bytes without redownload',
      () async {
        var requests = 0;
        final cache = MarketAssetDiskCache(
          directoryProvider: () async => directory,
          fetcher: (_) async {
            requests++;
            return Uint8List.fromList([1, 2, 3, 4]);
          },
        );

        final first = await cache.resolve(
          assetKey: 'crypto.btc',
          url: 'https://assets.example.test/btc-v1.png',
        );
        final second = await cache.resolve(
          assetKey: 'crypto.btc',
          url: 'https://assets.example.test/btc-v1.png',
        );

        expect(first, [1, 2, 3, 4]);
        expect(second, [1, 2, 3, 4]);
        expect(requests, 1);
      },
    );

    test('URL version change fetches only the changed asset', () async {
      var requests = 0;
      final cache = MarketAssetDiskCache(
        directoryProvider: () async => directory,
        fetcher: (_) async => Uint8List.fromList([++requests]),
      );

      final first = await cache.resolve(
        assetKey: 'flag.eu',
        url: 'https://assets.example.test/eu-v1.png',
      );
      final changed = await cache.resolve(
        assetKey: 'flag.eu',
        url: 'https://assets.example.test/eu-v2.png',
      );

      expect(first, [1]);
      expect(changed, [2]);
      expect(requests, 2);
    });

    test('rejects non-HTTPS URLs without making a request', () async {
      var requests = 0;
      final cache = MarketAssetDiskCache(
        directoryProvider: () async => directory,
        fetcher: (_) async {
          requests++;
          return Uint8List.fromList([1]);
        },
      );

      final result = await cache.resolve(
        assetKey: 'unsafe',
        url: 'http://assets.example.test/logo.png',
      );

      expect(result, isNull);
      expect(requests, 0);
    });
  });
}
