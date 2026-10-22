import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/crypto_market_repository.dart';
import 'tradingview_chart_screen.dart';

class CryptoBubbleScreen extends StatelessWidget {
  const CryptoBubbleScreen({super.key, required this.assets});

  final List<CryptoBubbleAsset> assets;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      titleSpacing: 4,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bubble Screener', style: TextStyle(fontSize: 18)),
          Text(
            'Live 24h crypto performance',
            style: TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
    body: assets.isEmpty
        ? const Center(
            child: Text(
              'Bubble data is unavailable right now.',
              style: TextStyle(color: TradeXColors.secondaryText),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: assets
                  .take(30)
                  .map((asset) {
                    final diameter =
                        78.0 +
                        math.min(
                          38,
                          math.log(math.max(1, asset.quoteVolume)) * 1.8,
                        );
                    final positive = asset.changePercent >= 0;
                    final color = positive
                        ? TradeXColors.success
                        : TradeXColors.error;
                    return Semantics(
                      button: true,
                      label:
                          '${asset.baseCurrency} ${asset.changePercent.toStringAsFixed(2)} percent',
                      child: InkWell(
                        key: ValueKey('crypto-bubble-${asset.symbol}'),
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TradingViewChartScreen(symbol: asset.symbol),
                          ),
                        ),
                        child: Ink(
                          width: diameter,
                          height: diameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: .14),
                            border: Border.all(
                              color: color.withValues(alpha: .72),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: .12),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                asset.baseCurrency,
                                style: const TextStyle(
                                  color: TradeXColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${positive ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
  );
}
