import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/tradex_colors.dart';

class TradingViewChartScreen extends StatefulWidget {
  const TradingViewChartScreen({
    super.key,
    required this.symbol,
    required this.segment,
  });

  final String symbol;
  final String segment;

  @override
  State<TradingViewChartScreen> createState() => _TradingViewChartScreenState();
}

class _TradingViewChartScreenState extends State<TradingViewChartScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF08111D))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_chartHtml(widget.symbol, widget.segment));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF08111D),
    appBar: AppBar(
      title: Text('${widget.symbol} · ${_segmentLabel(widget.segment)}'),
    ),
    body: Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          ),
      ],
    ),
  );
}

String _chartHtml(String symbol, String segment) {
  final tradingViewSymbol = tradingViewTicker(symbol, segment);
  final configuration = jsonEncode({
    'autosize': true,
    'symbol': tradingViewSymbol,
    'interval': '60',
    'timezone': 'Etc/UTC',
    'theme': 'dark',
    'style': '1',
    'locale': 'en',
    'backgroundColor': '#08111D',
    'gridColor': 'rgba(255, 255, 255, 0.04)',
    'hide_top_toolbar': true,
    'hide_side_toolbar': true,
    'hide_legend': false,
    'hide_volume': true,
    'allow_symbol_change': false,
    'calendar': false,
    'details': false,
    'hotlist': false,
    'save_image': false,
    'withdateranges': true,
    'watchlist': <String>[],
    'compareSymbols': <String>[],
    'studies': <String>[],
  });
  return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>
    html, body, .tradingview-widget-container,
    .tradingview-widget-container__widget { width:100%; height:100%; margin:0; background:#08111D; overflow:hidden; }
  </style>
</head>
<body>
  <div class="tradingview-widget-container">
    <div class="tradingview-widget-container__widget"></div>
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
      $configuration
    </script>
  </div>
</body>
</html>
''';
}

String tradingViewTicker(String symbol, String segment) {
  final cleanSymbol = symbol
      .replaceAll(RegExp('[^A-Za-z0-9]'), '')
      .toUpperCase();
  return segment == 'FUTURES'
      ? 'BINANCE:$cleanSymbol.P'
      : 'BINANCE:$cleanSymbol';
}

String _segmentLabel(String segment) =>
    segment == 'FUTURES' ? 'Futures' : 'Spot';
