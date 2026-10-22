import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/crypto_market_repository.dart';
import 'crypto_bubble_field.dart';
import 'crypto_market_cubit.dart';
import 'trading_view_chart_screen.dart';

class CryptoBubbleMapScreen extends StatefulWidget {
  const CryptoBubbleMapScreen({
    super.key,
    required this.assets,
    required this.repository,
    this.segment = 'SPOT',
  });

  final List<CryptoAsset> assets;
  final CryptoMarketRepository repository;
  final String segment;

  @override
  State<CryptoBubbleMapScreen> createState() => _CryptoBubbleMapScreenState();
}

class _CryptoBubbleMapScreenState extends State<CryptoBubbleMapScreen>
    with WidgetsBindingObserver {
  late final CryptoBubbleMapCubit _cubit;
  Timer? _refreshTimer;
  var _appIsActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = CryptoBubbleMapCubit(
      widget.repository,
      segment: widget.segment,
      initialGainers: widget.assets,
    );
    _cubit.initialize();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _appIsActive) _cubit.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: Scaffold(
      backgroundColor: const Color(0xFF07111C),
      appBar: AppBar(title: const Text('Live Crypto Map')),
      body: BlocConsumer<CryptoBubbleMapCubit, CryptoBubbleMapState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null &&
            current.assets.isNotEmpty,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (context, state) {
          final gainers = state.mode == CryptoBubbleMode.gainers;
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'CRYPTO · BINANCE · 24H',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<CryptoBubbleMode>(
                      key: const ValueKey('bubble-map-mode-selector'),
                      segments: const [
                        ButtonSegment(
                          value: CryptoBubbleMode.gainers,
                          icon: Icon(Icons.trending_up_rounded),
                          label: Text('Gainers'),
                        ),
                        ButtonSegment(
                          value: CryptoBubbleMode.losers,
                          icon: Icon(Icons.trending_down_rounded),
                          label: Text('Losers'),
                        ),
                      ],
                      selected: {state.mode},
                      onSelectionChanged: (selection) =>
                          _cubit.selectMode(selection.first),
                      showSelectedIcon: false,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          gainers ? 'Live Gainers Map' : 'Live Losers Map',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (state.refreshing)
                        const Padding(
                          padding: EdgeInsets.only(right: 9),
                          child: SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(strokeWidth: 1.7),
                          ),
                        ),
                      _LegendDot(
                        color: gainers
                            ? const Color(0xFF20D889)
                            : const Color(0xFFFF535D),
                        label: gainers ? 'Gain' : 'Loss',
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Continuous live movement · refreshes every 15s · tap for chart',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: _BubbleMapCanvas(state: state)),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _BubbleMapCanvas extends StatelessWidget {
  const _BubbleMapCanvas({required this.state});

  final CryptoBubbleMapState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.assets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: TradeXColors.goldBright),
      );
    }
    if (state.assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bubble data is unavailable.'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: context.read<CryptoBubbleMapCubit>().refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(820.0, constraints.maxWidth * 1.8);
        final height = math.max(680.0, constraints.maxHeight * 1.35);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1420),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: InteractiveViewer(
              constrained: false,
              minScale: .55,
              maxScale: 2.8,
              boundaryMargin: const EdgeInsets.all(120),
              child: SizedBox(
                width: width,
                height: height,
                child: CryptoBubbleField(
                  assets: state.assets,
                  minRadius: 28,
                  maxRadius: 70,
                  padding: 18,
                  speed: 9,
                  onBubbleTap: (asset) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TradingViewChartScreen(
                        symbol: asset.symbol,
                        segment: asset.segment,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
      ),
    ],
  );
}
