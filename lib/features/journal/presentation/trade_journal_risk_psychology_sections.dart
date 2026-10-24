import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _planBackground = Color(0xFF020C1B);
const _planSurface = Color(0xFF061A32);
const _planSurfaceRaised = Color(0xFF09213D);
const _planBorder = Color(0xFF16436A);
const _planGold = Color(0xFFFFC94D);
const _planBlue = Color(0xFF2499FF);
const _planGreen = Color(0xFF00E6B0);
const _planRed = Color(0xFFFF4658);
const _planPurple = Color(0xFFC34DFF);
const _planOrange = Color(0xFFFF922B);
const _planText = Color(0xFFF5F8FF);
const _planMuted = Color(0xFFA8B9D3);

class PriceRiskPlanSection extends StatelessWidget {
  const PriceRiskPlanSection({
    super.key,
    required this.plannedEntryController,
    required this.stopLossController,
    required this.takeProfitController,
    required this.riskAmountController,
    required this.direction,
    required this.symbol,
    required this.livePrice,
    required this.livePriceLoading,
    required this.entryRequired,
    required this.onUseLivePrice,
  });

  final TextEditingController plannedEntryController;
  final TextEditingController stopLossController;
  final TextEditingController takeProfitController;
  final TextEditingController riskAmountController;
  final String direction;
  final String symbol;
  final double? livePrice;
  final bool livePriceLoading;
  final bool entryRequired;
  final VoidCallback? onUseLivePrice;

  bool get _buy => direction.toLowerCase() != 'sell';

  String? _positivePrice(String? value, String label, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? '$label is required.' : null;
    final price = double.tryParse(text);
    if (price == null || price <= 0) return '$label must be greater than 0.';
    return null;
  }

  String? _stopLossValidator(String? value) {
    if (value?.trim().isEmpty ?? true) return null;
    final basic = _positivePrice(value, 'Stop Loss');
    if (basic != null) return basic;
    final entry = double.tryParse(plannedEntryController.text.trim());
    if (entry == null || entry <= 0) return 'Enter a valid Entry Price first.';
    final stopLoss = double.parse(value!.trim());
    if (_buy && stopLoss >= entry) {
      return 'BUY Stop Loss must be below Entry Price.';
    }
    if (!_buy && stopLoss <= entry) {
      return 'SELL Stop Loss must be above Entry Price.';
    }
    return null;
  }

  String? _takeProfitValidator(String? value) {
    if (value?.trim().isEmpty ?? true) return null;
    final basic = _positivePrice(value, 'Take Profit');
    if (basic != null) return basic;
    final entry = double.tryParse(plannedEntryController.text.trim());
    if (entry == null || entry <= 0) return 'Enter a valid Entry Price first.';
    final takeProfit = double.parse(value!.trim());
    if (_buy && takeProfit <= entry) {
      return 'BUY Take Profit must be above Entry Price.';
    }
    if (!_buy && takeProfit >= entry) {
      return 'SELL Take Profit must be below Entry Price.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => PremiumPlanSection(
    key: const ValueKey('price-risk-plan-section'),
    title: 'Price & Risk Plan',
    subtitle: 'Set a valid entry, stop loss, take profit and risk amount',
    icon: Icons.monetization_on_outlined,
    accent: _planGold,
    child: Column(
      children: [
        _LiveEntryContext(
          direction: direction,
          symbol: symbol,
          livePrice: livePrice,
          loading: livePriceLoading,
          onUseLivePrice: onUseLivePrice,
        ),
        const SizedBox(height: 9),
        PremiumRiskField(
          key: const ValueKey('risk-planned-entry'),
          label: '${_buy ? 'BUY' : 'SELL'} Entry Price',
          hint: 'e.g. 1.2345',
          icon: Icons.gps_fixed_rounded,
          accent: _planBlue,
          controller: plannedEntryController,
          step: .0001,
          validator: (value) =>
              _positivePrice(value, 'Entry Price', required: entryRequired),
        ),
        const SizedBox(height: 9),
        _ResponsivePlanGrid(
          children: [
            PremiumRiskField(
              key: const ValueKey('risk-stop-loss'),
              label: 'Stop Loss',
              hint: 'e.g. 1.2300',
              icon: Icons.shield_rounded,
              accent: _planRed,
              controller: stopLossController,
              step: .0001,
              validator: _stopLossValidator,
            ),
            PremiumRiskField(
              key: const ValueKey('risk-take-profit'),
              label: 'Take Profit',
              hint: 'e.g. 1.2400',
              icon: Icons.track_changes_rounded,
              accent: _planGreen,
              controller: takeProfitController,
              step: .0001,
              validator: _takeProfitValidator,
            ),
            PremiumRiskField(
              key: const ValueKey('risk-amount'),
              label: 'Risk in Amount',
              hint: 'e.g. 10',
              icon: Icons.savings_rounded,
              accent: _planOrange,
              controller: riskAmountController,
              validator: (value) => _positivePrice(value, 'Risk Amount'),
            ),
            RiskRewardDisplay(
              entryController: plannedEntryController,
              stopLossController: stopLossController,
              takeProfitController: takeProfitController,
              direction: direction,
            ),
          ],
        ),
      ],
    ),
  );
}

class RiskRewardDisplay extends StatelessWidget {
  const RiskRewardDisplay({
    super.key,
    required this.entryController,
    required this.stopLossController,
    required this.takeProfitController,
    required this.direction,
  });

  final TextEditingController entryController;
  final TextEditingController stopLossController;
  final TextEditingController takeProfitController;
  final String direction;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      entryController,
      stopLossController,
      takeProfitController,
    ]),
    builder: (context, _) {
      final ratio = _ratio;
      final hasAllLevels = [
        entryController,
        stopLossController,
        takeProfitController,
      ].every((controller) => controller.text.trim().isNotEmpty);
      return _FieldCard(
        key: const ValueKey('risk-reward-field'),
        label: 'Risk Reward',
        icon: Icons.balance_rounded,
        accent: _planGold,
        child: Container(
          key: const ValueKey('risk-reward-value'),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _planBackground.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: (ratio == null ? _planBorder : _planGold).withValues(
                alpha: .82,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ratio == null
                      ? hasAllLevels
                            ? 'Check entry, SL and TP'
                            : 'Enter levels to calculate'
                      : '1 : ${ratio.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ratio == null ? _planMuted : _planGold,
                    fontSize: ratio == null ? 12 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (ratio != null)
                const Text(
                  'R:R',
                  style: TextStyle(
                    color: _planMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  double? get _ratio {
    final entry = double.tryParse(entryController.text.trim());
    final stopLoss = double.tryParse(stopLossController.text.trim());
    final takeProfit = double.tryParse(takeProfitController.text.trim());
    if (entry == null || stopLoss == null || takeProfit == null) return null;
    final buy = direction.toLowerCase() != 'sell';
    final risk = buy ? entry - stopLoss : stopLoss - entry;
    final reward = buy ? takeProfit - entry : entry - takeProfit;
    if (risk <= 0 || reward <= 0) return null;
    return reward / risk;
  }
}

class _LiveEntryContext extends StatelessWidget {
  const _LiveEntryContext({
    required this.direction,
    required this.symbol,
    required this.livePrice,
    required this.loading,
    required this.onUseLivePrice,
  });

  final String direction;
  final String symbol;
  final double? livePrice;
  final bool loading;
  final VoidCallback? onUseLivePrice;

  @override
  Widget build(BuildContext context) {
    final buy = direction.toLowerCase() != 'sell';
    final accent = buy ? _planGreen : _planRed;
    final normalizedSymbol = symbol.trim().toUpperCase();
    return Container(
      key: const ValueKey('risk-live-price-context'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _planBlue.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _planBlue.withValues(alpha: .42)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: accent.withValues(alpha: .62)),
            ),
            child: Text(
              buy ? 'BUY' : 'SELL',
              key: const ValueKey('risk-selected-direction'),
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  normalizedSymbol.isEmpty
                      ? 'Select a symbol'
                      : normalizedSymbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _planText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                if (loading)
                  const Text(
                    'Loading live price…',
                    style: TextStyle(color: _planMuted, fontSize: 10.5),
                  )
                else
                  Text(
                    livePrice == null || livePrice! <= 0
                        ? 'Live price unavailable'
                        : 'Live Price · ${_formatLivePrice(livePrice!)}',
                    key: const ValueKey('risk-live-price'),
                    style: TextStyle(
                      color: livePrice == null ? _planMuted : _planBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          if (livePrice != null && livePrice! > 0)
            TextButton(
              key: const ValueKey('risk-use-live-price'),
              onPressed: onUseLivePrice,
              child: const Text('Use price'),
            ),
        ],
      ),
    );
  }
}

String _formatLivePrice(double value) {
  final decimals = value >= 1000
      ? 2
      : value >= 1
      ? 4
      : 8;
  return value.toStringAsFixed(decimals);
}

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
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_planSurfaceRaised, _planBackground],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _planBorder.withValues(alpha: .9)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .055),
          blurRadius: 22,
          spreadRadius: -7,
        ),
      ],
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
                    style: const TextStyle(
                      color: _planText,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _planMuted,
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
      style: const TextStyle(
        color: _planText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(hint).copyWith(
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
        _stepButton(Icons.keyboard_arrow_up_rounded, step),
        _stepButton(Icons.keyboard_arrow_down_rounded, -step),
      ],
    ),
  );

  Widget _stepButton(IconData icon, double delta) => InkWell(
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
    child: Icon(icon, color: _planText, size: 18),
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
        dropdownColor: _planSurfaceRaised,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _planText),
        style: const TextStyle(
          color: _planText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: _inputDecoration('Currency'),
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
  });

  final String? value;
  final List<String> emotions;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = <String>{...emotions};
    if (value?.isNotEmpty == true) values.add(value!);
    return _FieldCard(
      key: const ValueKey('psychology-emotion'),
      label: 'Emotion Before',
      icon: Icons.sentiment_satisfied_alt_rounded,
      accent: _planPurple,
      child: DropdownButtonFormField<String>(
        key: ValueKey('psychology-emotion-${value ?? 'none'}'),
        initialValue: value?.isNotEmpty == true ? value : null,
        isExpanded: true,
        dropdownColor: _planSurfaceRaised,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _planText),
        style: const TextStyle(
          color: _planText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: _inputDecoration('Select emotion'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Not selected')),
          for (final emotion in values)
            DropdownMenuItem(value: emotion, child: Text(_titleCase(emotion))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

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
                    color: value == score ? null : _planBackground,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: value == score
                          ? const Color(0xFFE186FF)
                          : _planBorder,
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
                    style: const TextStyle(
                      color: _planText,
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
      style: const TextStyle(color: _planText, height: 1.3),
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => Text(
            '$currentLength / $maxLength',
            style: const TextStyle(color: _planMuted, fontSize: 10),
          ),
      decoration: _inputDecoration(
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
      color: _planSurface.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _planPurple),
      boxShadow: [
        BoxShadow(color: _planPurple.withValues(alpha: .08), blurRadius: 16),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.playlist_add_check_rounded, color: _planPurple),
            SizedBox(width: 8),
            Text(
              'Checklist',
              style: TextStyle(
                color: _planText,
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
      color: _planSurfaceRaised.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _planBorder.withValues(alpha: .8)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _planPurple, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              color: _planText,
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
          inactiveThumbColor: _planMuted,
          inactiveTrackColor: _planBackground,
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
      color: _planSurface.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _planBorder.withValues(alpha: .92)),
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
                style: const TextStyle(
                  color: _planText,
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

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _planMuted, fontWeight: FontWeight.w500),
  filled: true,
  fillColor: _planBackground.withValues(alpha: .72),
  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide(color: _planBorder.withValues(alpha: .95)),
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
