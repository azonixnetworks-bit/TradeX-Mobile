part of '../trade_journal_strategy_section.dart';

class TradeSectionCard extends StatelessWidget {
  const TradeSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _strategySurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: .45)),
      boxShadow: [
        BoxShadow(color: accent.withValues(alpha: .045), blurRadius: 14),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        color: _strategyText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null)
                      TextSpan(
                        text: '  ($subtitle)',
                        style: const TextStyle(
                          color: _strategyMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.help_outline_rounded, color: accent, size: 18),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({
    required this.children,
    required this.preferredWidth,
    required this.maxColumns,
  });

  final List<Widget> children;
  final double preferredWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      final fitted = ((constraints.maxWidth + gap) / (preferredWidth + gap))
          .floor();
      final columns = fitted.clamp(1, maxColumns);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class TimeframeTrendCard extends StatelessWidget {
  const TimeframeTrendCard({
    super.key,
    required this.title,
    required this.timeframe,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String timeframe;
  final IconData icon;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _strategyBackground.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _strategyBorder),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: _strategyBlue),
            const SizedBox(width: 7),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: _strategyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: '  ($timeframe)',
                      style: const TextStyle(
                        color: _strategyMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (final option in const [
          ('UP', _strategyGreen, Icons.arrow_upward_rounded),
          ('DOWN', _strategyRed, Icons.arrow_downward_rounded),
          ('RANGE', _strategyBlue, Icons.swap_horiz_rounded),
        ]) ...[
          TrendOptionTile(
            key: ValueKey(
              'strategy-trend-$timeframe-${option.$1.toLowerCase()}',
            ),
            label: option.$1,
            color: option.$2,
            icon: option.$3,
            selected: selected == option.$1,
            onTap: () => onChanged(selected == option.$1 ? null : option.$1),
          ),
          if (option.$1 != 'RANGE') const SizedBox(height: 4),
        ],
      ],
    ),
  );
}

class TrendOptionTile extends StatelessWidget {
  const TrendOptionTile({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .18)
              : _strategySurfaceRaised.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? color : _strategyBorder.withValues(alpha: .7),
            width: selected ? 1.35 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: .17), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            _AnimatedCheck(selected: selected, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _strategyText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    ),
  );
}

class ZoneFindingCard extends StatelessWidget {
  const ZoneFindingCard({
    super.key,
    required this.timeframe,
    required this.selected,
    required this.onChanged,
  });

  final String timeframe;
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _MultipleChoiceCard(
    timeframe: timeframe,
    accent: _strategyPurple,
    options: const ['Supply / Demand', 'OrderFlow', 'FVG', 'Bank Trap Entry'],
    selected: selected,
    keyPrefix: 'strategy-zone',
    onChanged: onChanged,
  );
}

class TrendZoneSelector extends StatelessWidget {
  const TrendZoneSelector({
    super.key,
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _strategyGold.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _strategyGold.withValues(alpha: .38)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.gps_fixed_rounded, color: _strategyGold, size: 19),
            SizedBox(width: 7),
            Text(
              'Zone',
              style: TextStyle(
                color: _strategyText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ResponsiveCards(
          preferredWidth: 145,
          maxColumns: 3,
          children: [
            for (final option in options)
              PremiumCheckboxTile(
                key: ValueKey('$keyPrefix-${_selectionKey(option)}'),
                label: option,
                selected: selected.contains(option),
                accent: _strategyGold,
                onTap: () => onChanged(option),
              ),
          ],
        ),
      ],
    ),
  );
}

class ConfirmationFindingCard extends StatelessWidget {
  const ConfirmationFindingCard({
    super.key,
    required this.timeframe,
    required this.selected,
    required this.onChanged,
  });

  final String timeframe;
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _MultipleChoiceCard(
    timeframe: timeframe,
    accent: _strategyCyan,
    options: const ['MSS', 'X / Minor CHOCH', 'SMS', 'CSID'],
    selected: selected,
    keyPrefix: 'strategy-confirmation',
    onChanged: onChanged,
  );
}

class _MultipleChoiceCard extends StatelessWidget {
  const _MultipleChoiceCard({
    required this.timeframe,
    required this.accent,
    required this.options,
    required this.selected,
    required this.keyPrefix,
    required this.onChanged,
  });

  final String timeframe;
  final Color accent;
  final List<String> options;
  final Set<String> selected;
  final String keyPrefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: accent.withValues(alpha: .75)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: accent, size: 18),
            const SizedBox(width: 7),
            Text(
              timeframe,
              style: const TextStyle(
                color: _strategyText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (var index = 0; index < options.length; index++) ...[
          PremiumCheckboxTile(
            key: ValueKey(
              '$keyPrefix-$timeframe-${_selectionKey(options[index])}',
            ),
            label: options[index],
            selected: selected.contains(options[index]),
            accent: accent,
            onTap: () => onChanged(options[index]),
          ),
          if (index < options.length - 1) const SizedBox(height: 4),
        ],
      ],
    ),
  );
}

class PremiumCheckboxTile extends StatelessWidget {
  const PremiumCheckboxTile({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    button: true,
    label: label,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        constraints: const BoxConstraints(minHeight: 37),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: .18)
              : _strategySurfaceRaised.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : _strategyBlue.withValues(alpha: .27),
          ),
        ),
        child: Row(
          children: [
            _AnimatedCheck(selected: selected, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _strategyText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 170),
    width: 21,
    height: 21,
    decoration: BoxDecoration(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: selected ? color : const Color(0xFFA8C7F7),
        width: 1.7,
      ),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 130),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              key: ValueKey('checked'),
              color: Color(0xFF11151B),
              size: 16,
            )
          : const SizedBox(key: ValueKey('unchecked')),
    ),
  );
}

class DirectionSelector extends StatelessWidget {
  const DirectionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => TradeSectionCard(
    title: 'Direction',
    icon: Icons.turn_right_rounded,
    accent: _strategyGold,
    child: Row(
      children: [
        Expanded(
          child: _SelectorTile(
            key: const ValueKey('strategy-direction-pro'),
            label: 'Pro (With Trend)',
            selected: value == 'PRO',
            accent: _strategyGreen,
            onTap: () => onChanged(value == 'PRO' ? null : 'PRO'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _SelectorTile(
            key: const ValueKey('strategy-direction-counter'),
            label: 'Counter (Against)',
            selected: value == 'COUNTER',
            accent: _strategyGold,
            onTap: () => onChanged(value == 'COUNTER' ? null : 'COUNTER'),
          ),
        ),
      ],
    ),
  );
}

class EntryTypeSelector extends StatelessWidget {
  const EntryTypeSelector({
    super.key,
    required this.value,
    required this.status,
    required this.showStatusChoices,
    required this.onChanged,
    required this.onStatusChanged,
  });

  final String value;
  final String status;
  final bool showStatusChoices;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) => TradeSectionCard(
    title: 'Entry Type',
    icon: Icons.swap_vert_rounded,
    accent: _strategyGold,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _EntryTypeTile(
                key: const ValueKey('strategy-entry-buy'),
                label: 'Buy / Long',
                selected: value == 'buy',
                accent: _strategyGreen,
                icon: Icons.change_history_rounded,
                onTap: () => onChanged('buy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _EntryTypeTile(
                key: const ValueKey('strategy-entry-sell'),
                label: 'Sell / Short',
                selected: value == 'sell',
                accent: _strategyRed,
                icon: Icons.arrow_drop_down_rounded,
                onTap: () => onChanged('sell'),
              ),
            ),
          ],
        ),
        if (showStatusChoices) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EntryTypeTile(
                  key: const ValueKey('strategy-entry-planned'),
                  label: 'Plan',
                  selected: status == 'planned',
                  accent: _strategyGold,
                  icon: Icons.event_note_rounded,
                  onTap: () => onStatusChanged('planned'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EntryTypeTile(
                  key: const ValueKey('strategy-entry-open'),
                  label: 'Open Now',
                  selected: status == 'open',
                  accent: _strategyBlue,
                  icon: Icons.bolt_rounded,
                  onTap: () => onStatusChanged('open'),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: .18)
              : _strategySurfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent : _strategyBorder),
        ),
        child: Row(
          children: [
            _AnimatedCheck(selected: selected, color: accent),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  color: _strategyText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EntryTypeTile extends StatelessWidget {
  const _EntryTypeTile({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: .17)
              : _strategySurfaceRaised,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? accent : _strategyBorder),
          boxShadow: selected
              ? [BoxShadow(color: accent.withValues(alpha: .13), blurRadius: 9)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: 25),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _strategyText,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _AnimatedCheck(selected: selected, color: accent),
          ],
        ),
      ),
    ),
  );
}

class StrategySetupTextArea extends StatelessWidget {
  const StrategySetupTextArea({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TradeSectionCard(
    title: 'Strategy / Setup',
    subtitle: 'Optional',
    icon: Icons.edit_note_rounded,
    accent: _strategyGold,
    child: TextFormField(
      key: const ValueKey('strategy-setup-field'),
      controller: controller,
      minLines: 3,
      maxLines: 6,
      maxLength: 800,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      style: const TextStyle(color: _strategyText, height: 1.35),
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => Text(
            '$currentLength / $maxLength',
            style: TextStyle(
              color: isFocused ? _strategyGold : _strategyMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
      decoration: InputDecoration(
        hintText:
            'e.g. Order Block, FVG, Liquidity Sweep, Break & Retest, '
            'Kill Zone, Entry Model, etc...',
        hintStyle: TextStyle(
          color: _strategyMuted.withValues(alpha: .8),
          fontSize: 11,
        ),
        filled: true,
        fillColor: _strategyBackground.withValues(alpha: .72),
        contentPadding: const EdgeInsets.all(13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _strategyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _strategyGold, width: 1.35),
        ),
      ),
    ),
  );
}

class SaveTradeButton extends StatelessWidget {
  const SaveTradeButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE4BD61), Color(0xFFD4AF37)],
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: _strategyGold.withValues(alpha: .28),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('save-trade-button'),
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 52,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: busy
                  ? const SizedBox.square(
                      key: ValueKey('saving'),
                      dimension: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF11151B),
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      key: const ValueKey('ready'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: Color(0xFF11151B),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF11151B),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _selectionKey(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');
