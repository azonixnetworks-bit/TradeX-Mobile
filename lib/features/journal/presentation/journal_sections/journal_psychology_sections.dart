part of '../trade_journal_risk_psychology_sections.dart';

class PsychologyChecklistSection extends StatelessWidget {
  const PsychologyChecklistSection({
    super.key,
    required this.emotion,
    required this.emotions,
    required this.confidence,
    required this.mentalStateController,
    required this.checklist,
    required this.onEmotionChanged,
    required this.onConfidenceChanged,
    required this.onChecklistChanged,
  });

  final String? emotion;
  final List<String> emotions;
  final int? confidence;
  final TextEditingController mentalStateController;
  final Map<String, String> checklist;
  final ValueChanged<String?> onEmotionChanged;
  final ValueChanged<int> onConfidenceChanged;
  final void Function(String key, bool selected) onChecklistChanged;

  static const _items = <(String, String, IconData)>[
    (
      'followed_trading_plan',
      'Trading plan prepared',
      Icons.event_note_rounded,
    ),
    ('sl_planned', 'Stop loss planned', Icons.shield_rounded),
    ('tp_planned', 'Take profit planned', Icons.track_changes_rounded),
    ('session_checked', 'Session checked', Icons.schedule_rounded),
    ('news_checked', 'News checked', Icons.newspaper_rounded),
    ('risk_checked', 'Risk checked', Icons.trending_up_rounded),
    ('setup_confirmed', 'Setup confirmed', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) => PremiumPlanSection(
    key: const ValueKey('psychology-checklist-section'),
    title: 'Psychology & Checklist',
    subtitle: 'Track your mental state and trading checklist',
    icon: Icons.psychology_rounded,
    accent: _planPurple,
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final emotionField = PremiumEmotionField(
              value: emotion,
              emotions: emotions,
              onChanged: onEmotionChanged,
            );
            final confidenceField = ConfidenceSelector(
              value: confidence,
              onChanged: onConfidenceChanged,
            );
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  emotionField,
                  const SizedBox(height: 9),
                  confidenceField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: emotionField),
                const SizedBox(width: 12),
                Expanded(child: confidenceField),
              ],
            );
          },
        ),
        const SizedBox(height: 9),
        PremiumMentalStateField(controller: mentalStateController),
        const SizedBox(height: 10),
        _ChecklistCard(checklist: checklist, onChanged: onChecklistChanged),
      ],
    ),
  );
}

class PremiumPlanSection extends StatelessWidget {
  const PremiumPlanSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: context.isDarkMode
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.palette.surfaceRaised, context.palette.surface],
            )
          : null,
      color: context.palette.surface,
      borderRadius: TradeXRadii.card,
      border: Border.all(color: context.palette.border),
      boxShadow: TradeXElevation.surface(
        brightness: Theme.of(context).brightness,
        palette: context.palette,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.help_outline_rounded, color: _planBlue, size: 22),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}

class _ResponsivePlanGrid extends StatelessWidget {
  const _ResponsivePlanGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 9.0;
      final columns = constraints.maxWidth >= 620 ? 2 : 1;
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

class PremiumRiskField extends StatelessWidget {
  const PremiumRiskField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.controller,
    this.required = false,
    this.step,
    this.validator,
  });

  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
  final TextEditingController controller;
  final bool required;
  final double? step;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => _FieldCard(
    label: label,
    icon: icon,
    accent: accent,
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      validator:
          validator ??
          (required
              ? (value) =>
                    value?.trim().isEmpty == true ? '$label is required.' : null
              : null),
      style: TextStyle(
        color: context.palette.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(context, hint).copyWith(
        suffixIcon: step == null
            ? null
            : _NumberStepper(controller: controller, step: step!),
      ),
    ),
  );
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({required this.controller, required this.step});

  final TextEditingController controller;
  final double step;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepButton(context, Icons.keyboard_arrow_up_rounded, step),
        _stepButton(context, Icons.keyboard_arrow_down_rounded, -step),
      ],
    ),
  );

  Widget _stepButton(BuildContext context, IconData icon, double delta) =>
      InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          final current = double.tryParse(controller.text.trim()) ?? 0;
          final next = (current + delta).clamp(0, double.infinity);
          final decimals = step < .001
              ? 4
              : step < .1
              ? 2
              : 0;
          controller.text = next.toStringAsFixed(decimals);
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        },
        borderRadius: BorderRadius.circular(5),
        child: Icon(icon, color: context.palette.primaryText, size: 18),
      );
}

class PremiumCurrencyField extends StatelessWidget {
  const PremiumCurrencyField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim().toUpperCase();
    final values = <String>{
      'USD',
      'USDT',
      'EUR',
      'GBP',
      'LKR',
      if (current.isNotEmpty) current,
    };
    final selected = current.isEmpty ? 'USD' : current;
    return _FieldCard(
      key: const ValueKey('risk-currency'),
      label: 'Currency',
      icon: Icons.currency_exchange_rounded,
      accent: const Color(0xFF437BFF),
      child: DropdownButtonFormField<String>(
        key: ValueKey('risk-currency-$selected'),
        initialValue: selected,
        isExpanded: true,
        dropdownColor: context.palette.surfaceRaised,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: context.palette.primaryText,
        ),
        style: TextStyle(
          color: context.palette.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: _inputDecoration(context, 'Currency'),
        items: [
          for (final value in values)
            DropdownMenuItem(value: value, child: Text(value)),
        ],
        onChanged: (value) {
          if (value == null) return;
          controller.text = value;
          onChanged(value);
        },
      ),
    );
  }
}

class PremiumEmotionField extends StatelessWidget {
  const PremiumEmotionField({
    super.key,
    required this.value,
    required this.emotions,
    required this.onChanged,
    this.label = 'Emotion Before',
    this.fieldKey = const ValueKey('psychology-emotion'),
    this.optionKeyPrefix = 'emotion-option',
  });

  final String? value;
  final List<String> emotions;
  final ValueChanged<String?> onChanged;
  final String label;
  final Key fieldKey;
  final String optionKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final values = <String>{...emotions};
    if (value?.isNotEmpty == true) values.add(value!);
    return _FieldCard(
      key: fieldKey,
      label: label,
      icon: Icons.sentiment_satisfied_alt_rounded,
      accent: _planPurple,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 500
              ? 6
              : constraints.maxWidth >= 280
              ? 4
              : 3;
          return GridView.builder(
            key: ValueKey('psychology-emotion-${value ?? 'none'}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              mainAxisExtent: 82,
            ),
            itemBuilder: (context, index) {
              final emotion = values.elementAt(index);
              final selected = value == emotion;
              return Semantics(
                button: true,
                selected: selected,
                label: '${_titleCase(emotion)} emotion',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('$optionKeyPrefix-$emotion'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(selected ? null : emotion);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _planPurple.withValues(alpha: .34),
                                  const Color(0xFF7624FF)
                                      .withValues(alpha: .18),
                                ],
                              )
                            : null,
                        color: selected ? null : context.palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE186FF)
                              : context.palette.border,
                          width: selected ? 1.3 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _planPurple.withValues(alpha: .2),
                                  blurRadius: 12,
                                  spreadRadius: -3,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _emotionEmoji(emotion),
                            style: const TextStyle(fontSize: 26, height: 1),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _titleCase(emotion),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? context.palette.primaryText
                                  : context.palette.secondaryText,
                              fontSize: 9.5,
                              height: 1,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

const _emotionEmojis = <String, String>{
  'calm': '😌',
  'confident': '😎',
  'satisfied': '😊',
  'relieved': '😮‍💨',
  'disappointed': '😞',
  'fear': '😨',
  'fomo': '😬',
  'greed': '🤑',
  'angry': '😡',
  'revenge': '😡',
  'revenge_feeling': '😠',
  'overconfidence': '😏',
  'overconfident': '😏',
  'neutral': '😐',
  'hesitant': '🤔',
  'frustrated': '😤',
  'tired': '😴',
  'distracted': '🤯',
  'other': '🙂',
};

String _emotionEmoji(String emotion) =>
    _emotionEmojis[emotion.toLowerCase()] ?? '🙂';

class ConfidenceSelector extends StatelessWidget {
  const ConfidenceSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => _FieldCard(
    key: const ValueKey('psychology-confidence'),
    label: 'Confidence (1 – 5)',
    icon: Icons.bar_chart_rounded,
    accent: _planPurple,
    child: Row(
      children: [
        for (var score = 1; score <= 5; score++) ...[
          Expanded(
            child: Semantics(
              selected: value == score,
              button: true,
              label: 'Confidence $score',
              child: InkWell(
                key: ValueKey('confidence-$score'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(score);
                },
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: value == score
                        ? const LinearGradient(
                            colors: [Color(0xFFC34DFF), Color(0xFF7624FF)],
                          )
                        : null,
                    color: value == score ? null : context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: value == score
                          ? const Color(0xFFE186FF)
                          : context.palette.border,
                    ),
                    boxShadow: value == score
                        ? [
                            BoxShadow(
                              color: _planPurple.withValues(alpha: .27),
                              blurRadius: 9,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (score < 5) const SizedBox(width: 6),
        ],
      ],
    ),
  );
}

class PremiumMentalStateField extends StatelessWidget {
  const PremiumMentalStateField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => _FieldCard(
    key: const ValueKey('psychology-mental-note'),
    label: 'Mental-state Note',
    icon: Icons.note_alt_rounded,
    accent: _planPurple,
    child: TextFormField(
      key: const ValueKey('mental-state-note-field'),
      controller: controller,
      minLines: 3,
      maxLines: 5,
      maxLength: 300,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      style: TextStyle(color: context.palette.primaryText, height: 1.3),
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => Text(
            '$currentLength / $maxLength',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 10,
            ),
          ),
      decoration: _inputDecoration(
        context,
        'e.g. I feel confident about this setup because...',
      ),
    ),
  );
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.checklist, required this.onChanged});

  final Map<String, String> checklist;
  final void Function(String key, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('premium-trade-checklist'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _planPurple),
      boxShadow: [
        BoxShadow(color: _planPurple.withValues(alpha: .08), blurRadius: 16),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.playlist_add_check_rounded, color: _planPurple),
            SizedBox(width: 8),
            Text(
              'Checklist',
              style: TextStyle(
                color: context.palette.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 7),
            Icon(Icons.help_outline_rounded, color: _planBlue, size: 18),
          ],
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final columns = constraints.maxWidth >= 620 ? 2 : 1;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: 7,
              children: [
                for (final item in PsychologyChecklistSection._items)
                  SizedBox(
                    width: width,
                    child: PremiumChecklistTile(
                      key: ValueKey('checklist-${item.$1}'),
                      label: item.$2,
                      icon: item.$3,
                      selected: checklist[item.$1] == 'yes',
                      onChanged: (selected) => onChanged(item.$1, selected),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class PremiumChecklistTile extends StatelessWidget {
  const PremiumChecklistTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    padding: const EdgeInsets.only(left: 10, right: 5),
    decoration: BoxDecoration(
      color: context.palette.surfaceRaised,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: context.palette.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: _planPurple, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            style: TextStyle(
              color: context.palette.primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch.adaptive(
          value: selected,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            onChanged(value);
          },
          activeThumbColor: const Color(0xFF8CFFE1),
          activeTrackColor: const Color(0xFF00B985),
          inactiveThumbColor: context.palette.secondaryText,
          inactiveTrackColor: context.palette.surfaceMuted,
        ),
      ],
    ),
  );
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    super.key,
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
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: context.palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.help_outline_rounded, color: _planBlue, size: 18),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

InputDecoration _inputDecoration(BuildContext context, String hint) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.palette.secondaryText,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: context.palette.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: context.palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _planBlue, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _planRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _planRed, width: 1.25),
      ),
    );

String _titleCase(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
