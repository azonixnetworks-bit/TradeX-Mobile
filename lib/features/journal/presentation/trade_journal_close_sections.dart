import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/trade_journal_models.dart';
import 'trade_journal_risk_psychology_sections.dart';
import 'trade_journal_ui.dart';

const closeTradeBackground = Color(0xFF020B1B);
const closeTradeSurface = Color(0xFF061A32);
const closeTradeRaised = Color(0xFF0A203D);
const closeTradeBorder = Color(0xFF225186);
const closeTradeGold = Color(0xFFFFC94D);
const closeTradeGreen = Color(0xFF00D5A5);
const closeTradeRed = Color(0xFFFF4658);
const closeTradePurple = Color(0xFFA94BFF);
const closeTradeBlue = Color(0xFF248EFF);
const closeTradeCyan = Color(0xFF18CEDC);
const closeTradeText = Color(0xFFF5F8FF);
const closeTradeMuted = Color(0xFF9EB3D1);

class CloseTradeSummaryCard extends StatelessWidget {
  const CloseTradeSummaryCard({super.key, required this.entry});

  final TradeJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final isBuy = const {'buy', 'long'}.contains(entry.direction.toLowerCase());
    final directionColor = isBuy ? closeTradeGreen : closeTradeRed;
    final stateColor = _statusColor(entry.status);
    return Container(
      key: const ValueKey('close-trade-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: _premiumDecoration(accent: closeTradeGreen, radius: 18),
      child: Row(
        children: [
          Container(
            key: const ValueKey('close-trade-avatar'),
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFDC6F), closeTradeGold],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x55FFC94D), blurRadius: 14)],
            ),
            child: Text(
              closeTradeSymbolInitials(entry.symbol),
              style: const TextStyle(
                color: Color(0xFF19213A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.symbol,
                  key: const ValueKey('close-trade-symbol'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: closeTradeText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 7,
                  runSpacing: 2,
                  children: [
                    Text(
                      titleCase(entry.market),
                      style: const TextStyle(
                        color: closeTradeMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      titleCase(entry.direction),
                      key: const ValueKey('close-trade-direction'),
                      style: TextStyle(
                        color: directionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            key: const ValueKey('close-trade-status'),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: stateColor.withValues(alpha: .75)),
              boxShadow: [
                BoxShadow(
                  color: stateColor.withValues(alpha: .16),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              entry.status.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                color: stateColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CloseTradeExitDetailsCard extends StatelessWidget {
  const CloseTradeExitDetailsCard({
    super.key,
    required this.exitPriceController,
    required this.exitPriceValidator,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
    required this.result,
    required this.onResultChanged,
    required this.livePrice,
    required this.livePriceLoading,
    required this.onRefreshLivePrice,
    required this.onUseLivePrice,
    required this.onExitPriceChanged,
  });

  final TextEditingController exitPriceController;
  final FormFieldValidator<String> exitPriceValidator;
  final String date;
  final String time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final String result;
  final ValueChanged<String> onResultChanged;
  final double? livePrice;
  final bool livePriceLoading;
  final VoidCallback onRefreshLivePrice;
  final VoidCallback? onUseLivePrice;
  final ValueChanged<String> onExitPriceChanged;

  @override
  Widget build(BuildContext context) => PremiumCloseTradeSection(
    title: 'Exit Details',
    subtitle: 'Record your exit price, date, time and result',
    icon: Icons.logout_rounded,
    accent: closeTradeBlue,
    child: Column(
      children: [
        _ResponsivePair(
          first: PremiumCloseTradePicker(
            key: const ValueKey('close-exit-date'),
            label: 'Exit Date',
            value: date,
            icon: Icons.calendar_month_rounded,
            accent: const Color(0xFF514BFF),
            onTap: onPickDate,
          ),
          second: PremiumCloseTradePicker(
            key: const ValueKey('close-exit-time'),
            label: 'Exit Time',
            value: time,
            icon: Icons.schedule_rounded,
            accent: closeTradeBlue,
            onTap: onPickTime,
          ),
        ),
        const SizedBox(height: 12),
        _ResponsivePair(
          first: PremiumCloseTradeNumberField(
            key: const ValueKey('close-exit-price'),
            controller: exitPriceController,
            label: 'Exit Price',
            hint: 'e.g. 1.2345',
            icon: Icons.monetization_on_outlined,
            accent: closeTradeBlue,
            validator: exitPriceValidator,
            onChanged: onExitPriceChanged,
            helperText: livePriceLoading
                ? 'Loading live price…'
                : livePrice == null
                ? 'Live price unavailable'
                : 'Live price · ${formatCloseTradePrice(livePrice!)}',
            suffix: livePriceLoading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: livePrice == null
                        ? 'Refresh live price'
                        : 'Use live price',
                    onPressed: livePrice == null
                        ? onRefreshLivePrice
                        : onUseLivePrice,
                    icon: Icon(
                      livePrice == null
                          ? Icons.refresh_rounded
                          : Icons.bolt_rounded,
                      color: closeTradeBlue,
                    ),
                  ),
          ),
          second: CloseTradeResultSelector(
            value: result,
            onChanged: onResultChanged,
          ),
        ),
      ],
    ),
  );
}

class CloseTradeResultSelector extends StatelessWidget {
  const CloseTradeResultSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _items = <(String, String, Color)>[
    ('win', 'WIN', closeTradeGold),
    ('loss', 'LOSS', closeTradeRed),
    ('breakeven', 'BE', closeTradeBlue),
    ('partial', 'PARTIAL', closeTradeCyan),
  ];

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: 'Result',
    icon: Icons.bar_chart_rounded,
    accent: closeTradeGold,
    child: Row(
      children: [
        for (var index = 0; index < _items.length; index++) ...[
          Expanded(
            child: _ResultSegment(
              key: ValueKey('close-result-${_items[index].$1}'),
              label: _items[index].$2,
              accent: _items[index].$3,
              selected: value == _items[index].$1,
              onTap: () => onChanged(_items[index].$1),
            ),
          ),
          if (index != _items.length - 1) const SizedBox(width: 4),
        ],
      ],
    ),
  );
}

class CloseTradeProfitLossCard extends StatelessWidget {
  const CloseTradeProfitLossCard({
    super.key,
    required this.grossController,
    required this.currency,
    required this.currencies,
    required this.onCurrencyChanged,
    required this.numberValidator,
  });

  final TextEditingController grossController;
  final String currency;
  final List<String> currencies;
  final ValueChanged<String?> onCurrencyChanged;
  final FormFieldValidator<String> numberValidator;

  @override
  Widget build(BuildContext context) => PremiumCloseTradeSection(
    title: 'P&L Details',
    subtitle: 'Record your trade outcome',
    icon: Icons.bar_chart_rounded,
    accent: closeTradeGreen,
    child: Column(
      children: [
        _ResponsivePair(
          first: PremiumCloseTradeNumberField(
            key: const ValueKey('close-gross-pnl'),
            controller: grossController,
            label: 'Gross P&L',
            hint: 'e.g. 50.00',
            icon: Icons.trending_up_rounded,
            accent: closeTradeGreen,
            signed: true,
            validator: numberValidator,
          ),
          second: PremiumCloseTradeDropdown(
            key: const ValueKey('close-pnl-currency'),
            label: 'P&L Currency',
            icon: Icons.monetization_on_outlined,
            accent: closeTradeBlue,
            value: currency,
            items: currencies,
            onChanged: onCurrencyChanged,
          ),
        ),
      ],
    ),
  );
}

class CloseTradeAdditionalInfoCard extends StatelessWidget {
  const CloseTradeAdditionalInfoCard({
    super.key,
    required this.emotion,
    required this.emotions,
    required this.onEmotionChanged,
    required this.followedPlan,
    required this.followedPlanOptions,
    required this.onFollowedPlanChanged,
    required this.otherEmotionController,
  });

  final String? emotion;
  final List<String> emotions;
  final ValueChanged<String?> onEmotionChanged;
  final String followedPlan;
  final List<String> followedPlanOptions;
  final ValueChanged<String?> onFollowedPlanChanged;
  final TextEditingController otherEmotionController;

  @override
  Widget build(BuildContext context) => PremiumCloseTradeSection(
    title: 'Additional Info',
    icon: Icons.note_alt_outlined,
    accent: closeTradeGreen,
    child: Column(
      children: [
        _ResponsivePair(
          breakpoint: 620,
          first: PremiumEmotionField(
            key: const ValueKey('close-emotion-after'),
            value: emotion,
            label: 'Emotion After',
            fieldKey: const ValueKey('close-emotion-after-field'),
            optionKeyPrefix: 'close-emotion-after-option',
            emotions: emotions,
            onChanged: onEmotionChanged,
          ),
          second: PremiumCloseTradeDropdown(
            key: const ValueKey('close-followed-plan'),
            label: 'Followed Plan?',
            icon: Icons.assignment_turned_in_outlined,
            accent: closeTradePurple,
            value: followedPlan,
            items: followedPlanOptions,
            onChanged: onFollowedPlanChanged,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: emotion == 'other'
              ? Padding(
                  key: const ValueKey('close-other-emotion-wrap'),
                  padding: const EdgeInsets.only(top: 12),
                  child: PremiumCloseTradeTextField(
                    key: const ValueKey('close-other-emotion'),
                    controller: otherEmotionController,
                    label: 'Describe emotion',
                    hint: 'How did you feel after the trade?',
                    icon: Icons.edit_note_rounded,
                    accent: closeTradePurple,
                    maxLength: 160,
                    validator: (value) => value?.trim().isEmpty == true
                        ? 'Please describe the emotion.'
                        : null,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class CloseTradeMistakesLessonsCard extends StatelessWidget {
  const CloseTradeMistakesLessonsCard({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.wentWellController,
    required this.wentWrongController,
    required this.lessonController,
    required this.improvementController,
    required this.rating,
    required this.onRatingChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final TextEditingController wentWellController;
  final TextEditingController wentWrongController;
  final TextEditingController lessonController;
  final TextEditingController improvementController;
  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) => PremiumCloseTradeSection(
    key: const ValueKey('close-mistakes-lessons'),
    title: 'Mistakes & Lessons',
    subtitle: 'Select what went wrong and write your learnings',
    icon: Icons.psychology_alt_rounded,
    accent: closeTradePurple,
    prominentBorder: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final item in options)
              MistakeSelectionChip(
                key: ValueKey('close-mistake-$item'),
                label: titleCase(item),
                selected: selected.contains(item),
                onTap: () => onToggle(item),
              ),
          ],
        ),
        const SizedBox(height: 15),
        _ResponsivePair(
          breakpoint: 620,
          first: CloseTradeReflectionField(
            key: const ValueKey('close-went-well'),
            controller: wentWellController,
            label: 'What went well?',
            hint: 'Good entry, followed the plan...',
            icon: Icons.trending_up_rounded,
            accent: closeTradeGreen,
          ),
          second: CloseTradeReflectionField(
            key: const ValueKey('close-went-wrong'),
            controller: wentWrongController,
            label: 'What went wrong?',
            hint: 'Entered early, emotional decision...',
            icon: Icons.trending_down_rounded,
            accent: closeTradeRed,
          ),
        ),
        const SizedBox(height: 12),
        _ResponsivePair(
          breakpoint: 620,
          first: CloseTradeReflectionField(
            key: const ValueKey('close-lesson-learned'),
            controller: lessonController,
            label: 'Lesson learned',
            hint: 'Wait for confirmation...',
            icon: Icons.menu_book_rounded,
            accent: closeTradePurple,
          ),
          second: CloseTradeReflectionField(
            key: const ValueKey('close-improvement'),
            controller: improvementController,
            label: 'Improvement for next trade',
            hint: 'Be more patient, follow rules...',
            icon: Icons.track_changes_rounded,
            accent: closeTradeCyan,
          ),
        ),
        const SizedBox(height: 14),
        CloseTradeStarRating(value: rating, onChanged: onRatingChanged),
      ],
    ),
  );
}

class MistakeSelectionChip extends StatelessWidget {
  const MistakeSelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF7A2034), Color(0xFF2B1733)],
              )
            : const LinearGradient(
                colors: [Color(0xFF0D2543), Color(0xFF07182E)],
              ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? closeTradeRed : closeTradeMuted,
          width: selected ? 1.3 : .8,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x33FF4658), blurRadius: 9)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? closeTradeRed : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? closeTradeRed : closeTradeMuted,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 13)
                      : null,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: closeTradeText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CloseTradeReflectionField extends StatelessWidget {
  const CloseTradeReflectionField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 3,
      maxLength: 300,
      inputFormatters: [LengthLimitingTextInputFormatter(300)],
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(color: closeTradeText, fontSize: 13),
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => Text(
            '$currentLength / ${maxLength ?? 300}',
            style: TextStyle(
              color: isFocused ? accent : closeTradeMuted,
              fontSize: 10,
            ),
          ),
      decoration: _inputDecoration(hint).copyWith(
        counterStyle: const TextStyle(color: closeTradeMuted, fontSize: 10),
      ),
    ),
  );
}

class CloseTradeStarRating extends StatelessWidget {
  const CloseTradeStarRating({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const heading = Row(
        children: [
          Icon(Icons.star_rounded, color: closeTradeGold, size: 30),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trade Rating',
                  style: TextStyle(
                    color: closeTradeText,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'How would you rate this trade?',
                  style: TextStyle(color: closeTradeMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      );
      final stars = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 1; index <= 5; index++)
            Semantics(
              button: true,
              selected: index <= value,
              label: '$index star rating',
              child: IconButton(
                key: ValueKey('close-rating-$index'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 39, minHeight: 44),
                padding: EdgeInsets.zero,
                onPressed: () => onChanged(index),
                icon: Icon(
                  index <= value
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: closeTradeGold,
                  size: 27,
                ),
              ),
            ),
        ],
      );
      if (constraints.maxWidth < 440) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            const SizedBox(height: 5),
            Align(alignment: Alignment.centerRight, child: stars),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: heading),
          stars,
        ],
      );
    },
  );
}

class CloseTradeSaveButton extends StatelessWidget {
  const CloseTradeSaveButton({
    super.key,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: enabled
          ? const [BoxShadow(color: Color(0x55FFC94D), blurRadius: 20)]
          : null,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFFFFE169), closeTradeGold]
              : const [Color(0xFF4B5261), Color(0xFF383E49)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: FilledButton.icon(
        key: const ValueKey('close-save-button'),
        onPressed: busy || !enabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF07111F),
          disabledForegroundColor: closeTradeMuted,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: busy
            ? const SizedBox.square(
                dimension: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF07111F),
                ),
              )
            : const Icon(Icons.save_rounded, size: 22),
        label: Text(
          busy ? 'Saving Review...' : 'Close & Save Review',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    ),
  );
}

class PremiumCloseTradeSection extends StatelessWidget {
  const PremiumCloseTradeSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.subtitle,
    this.prominentBorder = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;
  final bool prominentBorder;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _premiumDecoration(
      accent: accent,
      radius: 20,
      prominent: prominentBorder,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: closeTradeText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: closeTradeMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.help_outline_rounded,
              color: closeTradeBlue.withValues(alpha: .9),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class PremiumCloseTradePicker extends StatelessWidget {
  const PremiumCloseTradePicker({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: _inputBoxDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: closeTradeText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(icon, color: closeTradeMuted, size: 18),
          ],
        ),
      ),
    ),
  );
}

class PremiumCloseTradeNumberField extends StatelessWidget {
  const PremiumCloseTradeNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
    this.signed = false,
    this.validator,
    this.onChanged,
    this.helperText,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
  final bool signed;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      inputFormatters: [_DecimalTextInputFormatter(signed: signed)],
      style: const TextStyle(color: closeTradeText, fontSize: 15),
      decoration: _inputDecoration(hint)
          .copyWith(helperText: helperText, suffixIcon: suffix),
      validator: validator,
      onChanged: onChanged,
    ),
  );
}

String formatCloseTradePrice(double value) {
  final decimals = value >= 1000
      ? 2
      : value >= 1
      ? 4
      : 8;
  return value.toStringAsFixed(decimals);
}

class PremiumCloseTradeTextField extends StatelessWidget {
  const PremiumCloseTradeTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
    this.maxLength,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
  final int? maxLength;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: TextFormField(
      controller: controller,
      maxLength: maxLength,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: const TextStyle(color: closeTradeText),
      decoration: _inputDecoration(hint),
      validator: validator,
    ),
  );
}

class PremiumCloseTradeDropdown extends StatelessWidget {
  const PremiumCloseTradeDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : null;
    return _PremiumFieldShell(
      label: label,
      icon: icon,
      accent: accent,
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        dropdownColor: closeTradeRaised,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: const TextStyle(color: closeTradeText, fontSize: 14),
        decoration: _inputDecoration(''),
        hint: hint == null
            ? null
            : Text(hint!, style: const TextStyle(color: closeTradeMuted)),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(titleCase(item))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _PremiumFieldShell extends StatelessWidget {
  const _PremiumFieldShell({
    required this.label,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF09213E), Color(0xFF06182D)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: closeTradeBorder.withValues(alpha: .75)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: closeTradeText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(
              Icons.help_outline_rounded,
              color: closeTradeBlue,
              size: 17,
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.first,
    required this.second,
    this.breakpoint = 315,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint) {
        return Column(children: [first, const SizedBox(height: 10), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

class _ResultSegment extends StatelessWidget {
  const _ResultSegment({
    super.key,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 43,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(colors: [accent, accent.withValues(alpha: .72)])
            : null,
        color: selected ? null : const Color(0xFF07172C),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: selected ? accent : closeTradeMuted),
        boxShadow: selected
            ? [BoxShadow(color: accent.withValues(alpha: .30), blurRadius: 10)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? (accent == closeTradeGold
                          ? const Color(0xFF101522)
                          : closeTradeText)
                    : closeTradeText,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DecimalTextInputFormatter extends TextInputFormatter {
  const _DecimalTextInputFormatter({required this.signed});

  final bool signed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final expression = signed
        ? RegExp(r'^-?\d*\.?\d*$')
        : RegExp(r'^\d*\.?\d*$');
    return expression.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

BoxDecoration _premiumDecoration({
  required Color accent,
  required double radius,
  bool prominent = false,
}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF08213D), closeTradeSurface, Color(0xFF031329)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: accent.withValues(alpha: prominent ? .9 : .42),
    width: prominent ? 1.2 : 1,
  ),
  boxShadow: [
    BoxShadow(
      color: accent.withValues(alpha: prominent ? .10 : .05),
      blurRadius: prominent ? 18 : 12,
    ),
  ],
);

BoxDecoration _inputBoxDecoration() => BoxDecoration(
  color: const Color(0xFF07162B),
  borderRadius: BorderRadius.circular(11),
  border: Border.all(color: closeTradeMuted.withValues(alpha: .45)),
);

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF6F84A3)),
  filled: true,
  fillColor: const Color(0xFF07162B),
  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
  isDense: true,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide(color: closeTradeMuted.withValues(alpha: .45)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide(color: closeTradeMuted.withValues(alpha: .45)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: closeTradeBlue, width: 1.3),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: closeTradeRed),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: closeTradeRed, width: 1.3),
  ),
  errorStyle: const TextStyle(color: closeTradeRed, fontSize: 10),
);

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'open' => closeTradeGreen,
  'closed' => closeTradeBlue,
  'cancelled' => closeTradeRed,
  _ => closeTradeGold,
};

String closeTradeSymbolInitials(String symbol) {
  final normalized = symbol.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (normalized.isEmpty) return '—';
  const quotes = [
    'USDT',
    'USDC',
    'BUSD',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'BTC',
    'ETH',
  ];
  var base = normalized;
  for (final quote in quotes) {
    if (base.length > quote.length && base.endsWith(quote)) {
      base = base.substring(0, base.length - quote.length);
      break;
    }
  }
  final source = base.isEmpty ? normalized : base;
  return source.substring(0, source.length.clamp(0, 3));
}
