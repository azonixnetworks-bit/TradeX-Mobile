part of '../crypto_market_screen.dart';

class _CoinTrendPainter extends CustomPainter {
  const _CoinTrendPainter({required this.positive, required this.seed});

  final bool positive;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final color = positive ? const Color(0xFF20D8A0) : const Color(0xFFFF626B);
    final path = Path();
    const points = 7;
    for (var index = 0; index < points; index++) {
      final progress = index / (points - 1);
      final direction = positive ? 1 - progress : progress;
      final jitter = (random.nextDouble() - .5) * size.height * .24;
      final point = Offset(
        progress * size.width,
        (size.height * (.2 + direction * .58) + jitter).clamp(
          2,
          size.height - 2,
        ),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinTrendPainter oldDelegate) =>
      oldDelegate.positive != positive || oldDelegate.seed != seed;
}

class _CoinLogo extends StatelessWidget {
  const _CoinLogo({
    required this.asset,
    required this.size,
    required this.onTap,
  });
  final CryptoAsset asset;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${asset.symbol} TradingView chart',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: MarketInstrumentAvatar(
          market: 'CRYPTO',
          symbol: asset.symbol,
          baseCurrency: asset.baseCurrency,
          remoteUrl: asset.logoUrl,
          size: size,
        ),
      ),
    );
  }
}

class _MarketError extends StatelessWidget {
  const _MarketError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: TradeXColors.secondaryText,
          ),
          const SizedBox(height: 12),
          const Text('Live crypto market is temporarily unavailable.'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

Color _changeColor(double value) =>
    value >= 0 ? const Color(0xFF35D49A) : const Color(0xFFFF626B);

String _compact(double value) {
  if (value >= 1000000000000) {
    return '\$${(value / 1000000000000).toStringAsFixed(2)}T';
  }
  if (value >= 1000000000) {
    return '\$${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(2)}M';
  return '\$${value.toStringAsFixed(0)}';
}

String _price(double value) {
  if (value >= 1000) return '\$${value.toStringAsFixed(2)}';
  if (value >= 1) return '\$${value.toStringAsFixed(4)}';
  return '\$${value.toStringAsFixed(8)}';
}
