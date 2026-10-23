import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _strategyBackground = Color(0xFF020C1B);
const _strategySurface = Color(0xFF061A32);
const _strategySurfaceRaised = Color(0xFF09213D);
const _strategyBorder = Color(0xFF16436A);
const _strategyGold = Color(0xFFFFC94D);
const _strategyGreen = Color(0xFF00E6B0);
const _strategyRed = Color(0xFFFF4658);
const _strategyBlue = Color(0xFF2499FF);
const _strategyPurple = Color(0xFFC34DFF);
const _strategyCyan = Color(0xFF00DDF3);
const _strategyText = Color(0xFFF5F8FF);
const _strategyMuted = Color(0xFFA8B9D3);

class StrategyReasonSection extends StatelessWidget {
  const StrategyReasonSection({
    super.key,
    required this.htfTrends,
    required this.ltfTrends,
    required this.zoneFinding,
    required this.confirmationFinding,
    required this.direction,
    required this.entryType,
    required this.strategyController,
    required this.onHtfChanged,
    required this.onLtfChanged,
    required this.onZoneChanged,
    required this.onConfirmationChanged,
    required this.onDirectionChanged,
    required this.onEntryTypeChanged,
  });

  final Map<String, String> htfTrends;
  final Map<String, String> ltfTrends;
  final Map<String, Set<String>> zoneFinding;
  final Map<String, Set<String>> confirmationFinding;
  final String? direction;
  final String entryType;
  final TextEditingController strategyController;
  final void Function(String timeframe, String? trend) onHtfChanged;
  final void Function(String timeframe, String? trend) onLtfChanged;
  final void Function(String timeframe, String option) onZoneChanged;
  final void Function(String timeframe, String option) onConfirmationChanged;
  final ValueChanged<String?> onDirectionChanged;
  final ValueChanged<String> onEntryTypeChanged;

  static const _htf = <(String, String)>[
    ('Monthly', 'MN'),
    ('Weekly', 'W1'),
    ('Daily', 'D1'),
  ];
  static const _ltf = <(String, String)>[
    ('Hour 4', 'H4'),
    ('Hour 2', 'H2'),
    ('Hour 1', 'H1'),
    ('M45', 'M45'),
  ];
  static const _zoneFrames = ['M30', 'M15', 'M10', 'M7'];
  static const _confirmationFrames = ['M5', 'M3', 'M2', 'M1', '30s'];

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('strategy-reason-section'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_strategySurfaceRaised, _strategyBackground],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _strategyBorder.withValues(alpha: .85)),
      boxShadow: [
        BoxShadow(
          color: _strategyBlue.withValues(alpha: .08),
          blurRadius: 22,
          spreadRadius: -6,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StrategyHeader(),
        const SizedBox(height: 14),
        TradeSectionCard(
          title: 'HTF Trend',
          subtitle: 'Main Trend',
          icon: Icons.trending_up_rounded,
          accent: _strategyGold,
          child: _ResponsiveCards(
            preferredWidth: 150,
            maxColumns: 3,
            children: [
              for (final frame in _htf)
                TimeframeTrendCard(
                  key: ValueKey('strategy-htf-${frame.$2}'),
                  title: frame.$1,
                  timeframe: frame.$2,
                  icon: Icons.calendar_month_rounded,
                  selected: htfTrends[frame.$2],
                  onChanged: (trend) => onHtfChanged(frame.$2, trend),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'LTF Trend',
          subtitle: 'Lower Timeframe Trend',
          icon: Icons.candlestick_chart_rounded,
          accent: _strategyGold,
          child: _ResponsiveCards(
            preferredWidth: 150,
            maxColumns: 4,
            children: [
              for (final frame in _ltf)
                TimeframeTrendCard(
                  key: ValueKey('strategy-ltf-${frame.$2}'),
                  title: frame.$1,
                  timeframe: frame.$2,
                  icon: Icons.candlestick_chart_rounded,
                  selected: ltfTrends[frame.$2],
                  onChanged: (trend) => onLtfChanged(frame.$2, trend),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'Zone Finding',
          icon: Icons.gps_fixed_rounded,
          accent: _strategyPurple,
          child: _ResponsiveCards(
            preferredWidth: 150,
            maxColumns: 4,
            children: [
              for (final timeframe in _zoneFrames)
                ZoneFindingCard(
                  key: ValueKey('strategy-zone-$timeframe'),
                  timeframe: timeframe,
                  selected: zoneFinding[timeframe] ?? const {},
                  onChanged: (option) => onZoneChanged(timeframe, option),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'Confirmation Finding',
          icon: Icons.search_rounded,
          accent: _strategyCyan,
          child: _ResponsiveCards(
            preferredWidth: 150,
            maxColumns: 5,
            children: [
              for (final timeframe in _confirmationFrames)
                ConfirmationFindingCard(
                  key: ValueKey('strategy-confirmation-$timeframe'),
                  timeframe: timeframe,
                  selected: confirmationFinding[timeframe] ?? const {},
                  onChanged: (option) =>
                      onConfirmationChanged(timeframe, option),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 620;
            final directionSelector = DirectionSelector(
              value: direction,
              onChanged: onDirectionChanged,
            );
            final entrySelector = EntryTypeSelector(
              value: entryType,
              onChanged: onEntryTypeChanged,
            );
            if (stacked) {
              return Column(
                children: [
                  directionSelector,
                  const SizedBox(height: 10),
                  entrySelector,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: directionSelector),
                const SizedBox(width: 10),
                Expanded(child: entrySelector),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        StrategySetupTextArea(controller: strategyController),
      ],
    ),
  );
}

class _StrategyHeader extends StatelessWidget {
  const _StrategyHeader();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const identity = Row(
        children: [
          _TargetIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strategy & Reason',
                  style: TextStyle(
                    color: _strategyText,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Define your analysis and setup clearly',
                  style: TextStyle(color: _strategyMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
      if (constraints.maxWidth < 410) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            identity,
            SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: _TemplateLabel()),
          ],
        );
      }
      return const Row(
        children: [
          Expanded(child: identity),
          SizedBox(width: 8),
          _TemplateLabel(),
        ],
      );
    },
  );
}

class _TargetIcon extends StatelessWidget {
  const _TargetIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFE36A), Color(0xFFFFA812)],
      ),
      boxShadow: [
        BoxShadow(color: _strategyGold.withValues(alpha: .35), blurRadius: 16),
      ],
    ),
    child: const Icon(Icons.adjust_rounded, color: Color(0xFF132138)),
  );
}

class _TemplateLabel extends StatelessWidget {
  const _TemplateLabel();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Strategy templates are not configured yet',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _strategySurface.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _strategyGold.withValues(alpha: .45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, color: _strategyGold, size: 18),
          SizedBox(width: 6),
          Text(
            'Template',
            style: TextStyle(
              color: _strategyText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

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
    options: const ['Supply / Demand', 'OrderFlow', 'FVG'],
    selected: selected,
    keyPrefix: 'strategy-zone',
    onChanged: onChanged,
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
              color: Color(0xFF071523),
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
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TradeSectionCard(
    title: 'Entry Type',
    icon: Icons.swap_vert_rounded,
    accent: _strategyGold,
    child: Row(
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
        colors: [Color(0xFFFFE36A), Color(0xFFFFAF19)],
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
                        color: Color(0xFF071523),
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      key: const ValueKey('ready'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: Color(0xFF071523),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF071523),
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
