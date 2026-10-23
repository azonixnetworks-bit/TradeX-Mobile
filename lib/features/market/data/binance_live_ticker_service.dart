import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class BinanceLiveTicker {
  const BinanceLiveTicker({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.quoteVolume,
  });

  final String symbol;
  final double price;
  final double changePercent;
  final double quoteVolume;
}

typedef BinanceSocketConnector = Future<WebSocket> Function(String url);

/// Streams public Binance mini-tickers without using credentials.
///
/// Laravel remains the source of truth for the selected top-20 set. This
/// stream only refreshes price, 24h change and volume for those visible coins.
class BinanceLiveTickerService {
  BinanceLiveTickerService({BinanceSocketConnector? connect})
    : _connect = connect ?? WebSocket.connect;

  final BinanceSocketConnector _connect;

  Stream<Map<String, BinanceLiveTicker>> watch(String segment) async* {
    final normalizedSegment = segment.toUpperCase() == 'FUTURES'
        ? 'FUTURES'
        : 'SPOT';
    final url = normalizedSegment == 'FUTURES'
        ? 'wss://fstream.binance.com/ws/!miniTicker@arr'
        : 'wss://stream.binance.com:9443/ws/!miniTicker@arr';
    var retrySeconds = 1;

    while (true) {
      WebSocket? socket;
      try {
        socket = await _connect(url).timeout(const Duration(seconds: 8));
        socket.pingInterval = const Duration(seconds: 20);
        retrySeconds = 1;
        await for (final message in socket) {
          final updates = parseBinanceMiniTickerPayload(message);
          if (updates.isNotEmpty) yield updates;
        }
      } catch (_) {
        // Laravel's periodic refresh remains active while reconnecting.
      } finally {
        await socket?.close();
      }

      await Future<void>.delayed(Duration(seconds: retrySeconds));
      retrySeconds = math.min(15, retrySeconds * 2);
    }
  }
}

Map<String, BinanceLiveTicker> parseBinanceMiniTickerPayload(dynamic raw) {
  try {
    final decoded = jsonDecode(
      raw is String ? raw : utf8.decode(List<int>.from(raw as Iterable)),
    );
    if (decoded is! List) return const {};

    final updates = <String, BinanceLiveTicker>{};
    for (final item in decoded.whereType<Map>()) {
      final symbol = item['s']?.toString().toUpperCase() ?? '';
      if (!symbol.endsWith('USDT')) continue;

      final price = _number(item['c']);
      final open = _number(item['o']);
      final quoteVolume = _number(item['q']);
      if (price <= 0 || open <= 0) continue;

      updates[symbol] = BinanceLiveTicker(
        symbol: symbol,
        price: price,
        changePercent: ((price - open) / open) * 100,
        quoteVolume: quoteVolume,
      );
    }
    return updates;
  } catch (_) {
    return const {};
  }
}

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
