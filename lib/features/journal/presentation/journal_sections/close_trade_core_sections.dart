part of '../trade_journal_close_sections.dart';

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
                colors: [Color(0xFFE4BD61), closeTradeGold],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x55D4AF37), blurRadius: 14)],
            ),
            child: Text(
              closeTradeSymbolInitials(entry.symbol),
              style: const TextStyle(
                color: Color(0xFF11151B),
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
                colors: [Color(0xFF1B2633), Color(0xFF111923)],
              ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? closeTradeRed : closeTradeMuted,
          width: selected ? 1.3 : .8,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x33FF7575), blurRadius: 9)]
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
          ? const [BoxShadow(color: Color(0x55D4AF37), blurRadius: 20)]
          : null,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFFE4BD61), closeTradeGold]
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
          foregroundColor: const Color(0xFF11151B),
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
                  color: Color(0xFF11151B),
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
