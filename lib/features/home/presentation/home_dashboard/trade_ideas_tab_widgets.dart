part of '../home_dashboard_screen.dart';

// ignore: unused_element
class _MarketFilterBar extends StatelessWidget {
  const _MarketFilterBar({required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    const markets = ['All', 'Forex', 'Crypto', 'Gold'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: markets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return InkWell(
            onTap: () => onActionTap('${markets[index]} trade ideas'),
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: selected
                    ? TradeXColors.goldBright
                    : TradeXColors.surfaceRaised,
                border: Border.all(
                  color: selected
                      ? TradeXColors.goldBright
                      : TradeXColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  markets[index],
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF171308)
                        : TradeXColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _ExpandedIdeaCard extends StatelessWidget {
  const _ExpandedIdeaCard({
    required this.symbol,
    required this.market,
    required this.direction,
    required this.entry,
    required this.target,
    required this.stop,
    required this.status,
    required this.isPositive,
    required this.onTap,
  });

  final String symbol;
  final String market;
  final String direction;
  final String entry;
  final String target;
  final String stop;
  final String status;
  final bool isPositive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final directionColor = isPositive
        ? TradeXColors.success
        : TradeXColors.error;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(context),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                _SmallPill(label: market, color: TradeXColors.goldBright),
                const Spacer(),
                _SmallPill(
                  label: status,
                  color: status == 'ACTIVE'
                      ? TradeXColors.success
                      : TradeXColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _IdeaValue(
                    label: 'Direction',
                    value: direction,
                    color: directionColor,
                  ),
                ),
                Expanded(
                  child: _IdeaValue(label: 'Entry', value: entry),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IdeaValue(label: 'Take profit', value: target),
                ),
                Expanded(
                  child: _IdeaValue(
                    label: 'Stop loss',
                    value: stop,
                    color: TradeXColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Divider(color: TradeXColors.border, height: 1),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: TradeXColors.secondaryText,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'Updated moments ago',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: TradeXColors.goldBright,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdeaValue extends StatelessWidget {
  const _IdeaValue({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color ?? TradeXColors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .43)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// Kept as the original partial-screen visual reference.
// ignore: unused_element
