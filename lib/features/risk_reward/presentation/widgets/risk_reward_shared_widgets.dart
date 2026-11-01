part of '../risk_reward_module.dart';

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: SafeArea(child: child),
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
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15160F), TradeXColors.surface, Color(0xFF0A0D0C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TradeXColors.goldSoft.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(
            color: TradeXColors.gold.withValues(alpha: .08),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
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
                  color: active ? null : TradeXColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: active
                        ? TradeXColors.goldBright
                        : TradeXColors.borderStrong,
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
                        color: active ? Colors.black : TradeXColors.primaryText,
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
