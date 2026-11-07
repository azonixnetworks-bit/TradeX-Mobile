import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/tradex_design_system.dart';
import 'market_asset_cache.dart';
import 'market_asset_resolver.dart';

class MarketInstrumentAvatar extends StatelessWidget {
  const MarketInstrumentAvatar({
    super.key,
    required this.market,
    required this.symbol,
    this.baseCurrency,
    this.remoteUrl,
    this.size = 58,
  });

  final String market;
  final String symbol;
  final String? baseCurrency;
  final String? remoteUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = MarketAssetResolver.resolve(
      market: market,
      symbol: symbol,
      baseCurrency: baseCurrency,
    );
    final fallback = _LocalMarketVisual(visual: visual, size: size);
    final url = remoteUrl?.trim() ?? '';
    return Semantics(
      image: true,
      label: '$symbol market identity',
      child: url.isEmpty
          ? fallback
          : _PersistentMarketImage(
              assetKey: '${market.toLowerCase()}.${symbol.toLowerCase()}',
              url: url,
              size: size,
              fallback: fallback,
            ),
    );
  }
}

class _PersistentMarketImage extends StatefulWidget {
  const _PersistentMarketImage({
    required this.assetKey,
    required this.url,
    required this.size,
    required this.fallback,
  });

  final String assetKey;
  final String url;
  final double size;
  final Widget fallback;

  @override
  State<_PersistentMarketImage> createState() => _PersistentMarketImageState();
}

class _PersistentMarketImageState extends State<_PersistentMarketImage> {
  late Future<Uint8List?> _future = _load();

  Future<Uint8List?> _load() => MarketAssetDiskCache.instance.resolve(
    assetKey: widget.assetKey,
    url: widget.url,
  );

  @override
  void didUpdateWidget(covariant _PersistentMarketImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.assetKey != widget.assetKey) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _future,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null || bytes.isEmpty) return widget.fallback;
      return ClipOval(
        child: Image.memory(
          bytes,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => widget.fallback,
        ),
      );
    },
  );
}

class _LocalMarketVisual extends StatelessWidget {
  const _LocalMarketVisual({required this.visual, required this.size});

  final MarketAssetVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (visual.hasPair) {
      final badgeSize = size * .72;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            if (visual.baseAsset != null)
              Positioned(
                left: 0,
                top: 0,
                child: _AssetBadge(path: visual.baseAsset!, size: badgeSize),
              ),
            if (visual.quoteAsset != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: _AssetBadge(path: visual.quoteAsset!, size: badgeSize),
              ),
          ],
        ),
      );
    }
    final primary = visual.primaryAsset;
    if (primary != null) return _AssetBadge(path: primary, size: size);
    final label = visual.label.isEmpty
        ? '?'
        : visual.label.substring(0, visual.label.length.clamp(0, 3));
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.goldSoft,
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.gold.withValues(alpha: .6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.palette.goldText,
          fontSize: size * .2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AssetBadge extends StatelessWidget {
  const _AssetBadge({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .08),
    decoration: BoxDecoration(
      color: context.palette.surfaceRaised,
      shape: BoxShape.circle,
      border: Border.all(color: context.palette.borderStrong),
    ),
    child: ClipOval(
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.show_chart_rounded,
          color: context.palette.gold,
          size: size * .5,
        ),
      ),
    ),
  );
}
