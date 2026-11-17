part of '../trade_journal_risk_psychology_sections.dart';

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
        PremiumRiskField(
          key: const ValueKey('risk-stop-loss'),
          label: 'Stop Loss',
          hint: _buy ? 'Below Entry Price' : 'Above Entry Price',
          icon: Icons.shield_rounded,
          accent: _planRed,
          controller: stopLossController,
          step: .0001,
          validator: _stopLossValidator,
        ),
        const SizedBox(height: 9),
        PremiumRiskField(
          key: const ValueKey('risk-take-profit'),
          label: 'Take Profit',
          hint: _buy ? 'Above Entry Price' : 'Below Entry Price',
          icon: Icons.track_changes_rounded,
          accent: _planGreen,
          controller: takeProfitController,
          step: .0001,
          validator: _takeProfitValidator,
        ),
        const SizedBox(height: 9),
        _ResponsivePlanGrid(
          children: [
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
            color: context.palette.surfaceMuted,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: (ratio == null ? context.palette.border : _planGold)
                  .withValues(alpha: .82),
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
                    color: ratio == null
                        ? context.palette.secondaryText
                        : _planGold,
                    fontSize: ratio == null ? 12 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (ratio != null)
                Text(
                  'R:R',
                  style: TextStyle(
                    color: context.palette.secondaryText,
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
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                if (loading)
                  Text(
                    'Loading live price…',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 10.5,
                    ),
                  )
                else
                  Text(
                    livePrice == null || livePrice! <= 0
                        ? 'Live price unavailable'
                        : 'Live Price · ${_formatLivePrice(livePrice!)}',
                    key: const ValueKey('risk-live-price'),
                    style: TextStyle(
                      color: livePrice == null
                          ? context.palette.secondaryText
                          : _planBlue,
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
