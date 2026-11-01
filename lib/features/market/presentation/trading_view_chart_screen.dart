import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/serialization/structured_text_codec.dart';

class TradingViewChartScreen extends StatefulWidget {
  const TradingViewChartScreen({
    super.key,
    required this.symbol,
    required this.segment,
  }) : qualifiedSymbol = null,
       interval = '60';

  const TradingViewChartScreen.qualified({
    super.key,
    required this.qualifiedSymbol,
    required this.interval,
  }) : symbol = '',
       segment = '';

  final String symbol;
  final String segment;
  final String? qualifiedSymbol;
  final String interval;

  @override
  State<TradingViewChartScreen> createState() => _TradingViewChartScreenState();
}

class _TradingViewChartScreenState extends State<TradingViewChartScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: TradingViewChartView(
              qualifiedSymbol:
                  widget.qualifiedSymbol ??
                  tradingViewTicker(widget.symbol, widget.segment),
              interval: widget.interval,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton.filledTonal(
              tooltip: 'Close chart',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ),
      ],
    ),
  );
}

class TradingViewChartView extends StatefulWidget {
  const TradingViewChartView({
    super.key,
    required this.qualifiedSymbol,
    required this.interval,
  });

  final String qualifiedSymbol;
  final String interval;

  @override
  State<TradingViewChartView> createState() => _TradingViewChartViewState();
}

class _TradingViewChartViewState extends State<TradingViewChartView>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(TradeXColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final trusted =
                uri != null &&
                (uri.scheme == 'about' ||
                    (uri.scheme == 'https' &&
                        uri.host.toLowerCase().endsWith('tradingview.com')));
            return trusted
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            setState(() {
              _loading = false;
              _error = 'Live chart could not be loaded.';
            });
          },
        ),
      );
    _load();
  }

  @override
  void didUpdateWidget(covariant TradingViewChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qualifiedSymbol != widget.qualifiedSymbol ||
        oldWidget.interval != widget.interval) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    await _controller.loadHtmlString(
      buildTradingViewChartHtml(
        widget.qualifiedSymbol,
        interval: widget.interval,
      ),
      baseUrl: 'https://www.tradingview.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const ColoredBox(
            color: TradeXColors.background,
            child: Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            ),
          ),
        if (_error != null)
          ColoredBox(
            color: TradeXColors.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: TradeXColors.secondaryText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: TradeXColors.secondaryText),
                  ),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String buildTradingViewChartHtml(
  String qualifiedSymbol, {
  required String interval,
}) {
  final configuration = encodeStructuredText({
    'autosize': true,
    'symbol': qualifiedSymbol,
    'interval': interval,
    'timezone': 'Etc/UTC',
    'theme': 'dark',
    'style': '1',
    'locale': 'en',
    'backgroundColor': '#050706',
    'gridColor': 'rgba(255, 255, 255, 0.04)',
    'hide_top_toolbar': false,
    'hide_side_toolbar': false,
    'hide_legend': false,
    'hide_volume': true,
    'allow_symbol_change': false,
    'save_image': true,
    'withdateranges': true,
  });
  return '''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<style>html,body,.tradingview-widget-container,.tradingview-widget-container__widget{width:100%;height:100%;margin:0;background:#050706;overflow:hidden}.tradingview-widget-copyright{display:none}</style>
</head><body><div class="tradingview-widget-container"><div class="tradingview-widget-container__widget"></div>
<script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>$configuration</script>
</div></body></html>''';
}

String tradingViewTicker(String symbol, String segment) {
  final clean = symbol.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  return segment == 'FUTURES' ? 'BINANCE:$clean.P' : 'BINANCE:$clean';
}
