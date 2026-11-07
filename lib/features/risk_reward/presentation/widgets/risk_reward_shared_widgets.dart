part of '../risk_reward_module.dart';

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.background,
    body: SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.palette.gold.withValues(
                        alpha: context.isDarkMode ? .09 : .05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

class _CalculatorCanvas extends StatelessWidget {
  const _CalculatorCanvas({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 54,
        right: -18,
        child: IgnorePointer(
          child: Opacity(
            opacity: context.isDarkMode ? .08 : .12,
            child: Image.asset(
              '$_assetRoot/02_forex_candlesticks.png',
              width: 138,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      Positioned(
        left: -80,
        right: -80,
        bottom: -68,
        child: IgnorePointer(
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(260, 68),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.palette.gold.withValues(
                    alpha: context.isDarkMode ? .06 : .075,
                  ),
                  context.palette.surface.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: child,
        ),
      ),
    ],
  );
}

class _CalculatorHero extends StatelessWidget {
  const _CalculatorHero({
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 48),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: const TextStyle(
              color: TradeXColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 7),
        ],
        Text(
          title,
          style: TextStyle(
            color: context.palette.primaryText,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: TextStyle(
            color: context.palette.secondaryText,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.goldBright,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 3,
    ),
  );
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.first, required this.second});

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 2,
    children: [
      Text(
        first,
        style: const TextStyle(
          color: TradeXColors.primaryText,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [TradeXColors.goldBright, Color(0xFFFFE29A)],
        ).createShader(bounds),
        child: Text(
          second,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ),
    ],
  );
}

class _PageSubtitle extends StatelessWidget {
  const _PageSubtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.secondaryText,
      fontSize: 14,
      height: 1.45,
    ),
  );
}

class _GoldCard extends StatelessWidget {
  const _GoldCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final decoration = BoxDecoration(
      color: palette.surface,
      gradient: context.isDarkMode
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.surfaceRaised, palette.surface],
            )
          : null,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: palette.border),
      boxShadow: TradeXElevation.surface(
        brightness: Theme.of(context).brightness,
        palette: palette,
      ),
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _AssetImage extends StatelessWidget {
  const _AssetImage(this.name, {required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    '$_assetRoot/$name',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => SizedBox.square(
      dimension: size,
      child: const Icon(
        Icons.calculate_rounded,
        color: TradeXColors.goldBright,
      ),
    ),
  );
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final itemWidth = values.length <= 2
          ? (constraints.maxWidth - 8) / values.length
          : (constraints.maxWidth - 16) / values.length;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(values.length, (index) {
          final active = values[index] == selected;
          return SizedBox(
            width: itemWidth,
            child: Semantics(
              selected: active,
              button: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [TradeXColors.goldBright, Color(0xFFE0A51C)],
                        )
                      : null,
                  color: active ? null : context.palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: active
                        ? TradeXColors.goldBright
                        : context.palette.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => onSelected(values[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 13,
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: active
                            ? Colors.black
                            : context.palette.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: values.length > 2 ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    },
  );
}

RiskRewardInstrument? _instrumentBySymbol(
  List<RiskRewardInstrument> instruments,
  String? symbol,
) {
  if (symbol == null) return null;
  for (final instrument in instruments) {
    if (instrument.symbol == symbol) return instrument;
  }
  return null;
}
