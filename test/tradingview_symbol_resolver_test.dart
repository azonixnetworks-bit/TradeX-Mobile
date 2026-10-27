import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/trade_ideas/services/tradingview_symbol_resolver.dart';

void main() {
  const resolver = TradeIdeaTradingViewSymbolResolver();

  test('resolves only category-aware verified mappings', () {
    expect(
      resolver.resolve(category: 'FOREX', symbol: 'XAUUSD'),
      'OANDA:XAUUSD',
    );
    expect(
      resolver.resolve(category: 'CRYPTO', symbol: 'BTCUSDT'),
      'BINANCE:BTCUSDT',
    );
    expect(
      resolver.resolve(category: 'DERIV', symbol: 'NAS100'),
      'OANDA:NAS100USD',
    );
    expect(resolver.resolve(category: 'STOCKS', symbol: 'AAPL'), isNull);
    expect(
      resolver.resolve(category: 'STOCKS', symbol: 'NASDAQ:AAPL'),
      'NASDAQ:AAPL',
    );
    expect(resolver.resolve(category: 'STOCKS', symbol: 'EVIL:AAPL'), isNull);
  });

  test('maps supported timeframes exactly', () {
    expect(tradeIdeaTradingViewInterval('M15'), '15');
    expect(tradeIdeaTradingViewInterval('H4'), '240');
    expect(tradeIdeaTradingViewInterval('D1'), 'D');
  });

  test('accepts only safe TradingView analysis URLs', () {
    expect(
      isSafeTradingViewAnalysisUrl('https://www.tradingview.com/chart/abc/'),
      isTrue,
    );
    expect(
      isSafeTradingViewAnalysisUrl('https://www.tradingview.com/x/abc/'),
      isTrue,
    );
    expect(
      isSafeTradingViewAnalysisUrl('https://example.com/chart/abc'),
      isFalse,
    );
    expect(
      isSafeTradingViewAnalysisUrl('http://tradingview.com/chart/abc'),
      isFalse,
    );
  });
}
