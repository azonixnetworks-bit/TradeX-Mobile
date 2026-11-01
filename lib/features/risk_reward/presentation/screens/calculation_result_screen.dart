part of '../risk_reward_module.dart';

class CalculationResultScreen extends StatelessWidget {
  const CalculationResultScreen({
    super.key,
    required this.input,
    this.result,
    this.dividendResult,
    required this.type,
    this.onNewCalculation,
  });

  final Map<String, dynamic> input;
  final RiskRewardResult? result;
  final DividendResult? dividendResult;
  final String type;
  final VoidCallback? onNewCalculation;

  @override
  Widget build(BuildContext context) {
    final isDividend = type == 'dividend';
    final title = isDividend ? dividendResult!.symbol : result!.symbol;
    return _FeaturePage(
      child: ListView(
        key: const ValueKey('calculation-result-details'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          const _GradientTitle(first: 'Calculation', second: 'Result'),
          const SizedBox(height: 8),
          const _PageSubtitle(
            'Server-calculated position size and planning details.',
          ),
          const SizedBox(height: 18),
          _GoldCard(
            child: Row(
              children: [
                _AssetImage(
                  isDividend
                      ? '24_dividend_hand_coin_tile.png'
                      : '09_eurusd_currency_badge.png',
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isDividend && result!.side.isNotEmpty)
                  _SideBadge(result!.side),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isDividend)
            _DividendResultDetails(result: dividendResult!)
          else
            _RiskResultDetails(result: result!),
          const SizedBox(height: 14),
          _JsonDetailCard(
            title: 'Calculation Details',
            data: isDividend ? dividendResult!.data : result!.data,
          ),
          const SizedBox(height: 14),
          const _StatusNotice(
            text: 'This is a planning estimate. Verify live prices, spread, slippage, fees, leverage tiers and broker specifications before trading.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: context.watch<RiskRewardCubit>().state.saving
                      ? null
                      : () => _save(context),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    context.read<RiskRewardCubit>().clearResult();
                    onNewCalculation?.call();
                    Navigator.of(context).pop();
                  },
                  child: const Text('New Calculation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<RiskRewardCubit>().saveCurrent(
      type: type,
      input: input,
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Calculation saved.' : 'Unable to save calculation.',
        ),
      ),
    );
  }
}

class _CurrentResult extends StatelessWidget {
  const _CurrentResult({required this.input, required this.onNewCalculation});

  final Map<String, dynamic>? input;
  final VoidCallback onNewCalculation;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RiskRewardCubit, RiskRewardState>(
        buildWhen: (previous, current) =>
            previous.result != current.result ||
            previous.submitting != current.submitting ||
            previous.error != current.error,
        builder: (context, state) {
          if (state.submitting) {
            return const _CenteredLoader(
              label: 'Calculating with server rules…',
              compact: true,
            );
          }
          if (state.error != null) return _ErrorNotice(state.error!);
          final result = state.result;
          if (result == null || input == null) return const SizedBox.shrink();
          return Column(
            children: [
              _RiskResultDetails(result: result, compact: true),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _open(
                    context,
                    CalculationResultScreen(
                      input: input!,
                      result: result,
                      type: 'risk_reward',
                      onNewCalculation: onNewCalculation,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('View Calculation Details'),
                ),
              ),
            ],
          );
        },
      );
}

class _CurrentDividendResult extends StatelessWidget {
  const _CurrentDividendResult({
    required this.input,
    required this.onNewCalculation,
  });

  final Map<String, dynamic>? input;
  final VoidCallback onNewCalculation;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RiskRewardCubit, RiskRewardState>(
        buildWhen: (previous, current) =>
            previous.dividendResult != current.dividendResult ||
            previous.submitting != current.submitting ||
            previous.error != current.error,
        builder: (context, state) {
          if (state.submitting) {
            return const _CenteredLoader(
              label: 'Calculating dividend estimate…',
              compact: true,
            );
          }
          if (state.error != null) return _ErrorNotice(state.error!);
          final result = state.dividendResult;
          if (result == null || input == null) return const SizedBox.shrink();
          return Column(
            children: [
              _DividendResultDetails(result: result),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _open(
                    context,
                    CalculationResultScreen(
                      input: input!,
                      dividendResult: result,
                      type: 'dividend',
                      onNewCalculation: onNewCalculation,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('View Calculation Details'),
                ),
              ),
            ],
          );
        },
      );
}

class _RiskResultDetails extends StatelessWidget {
  const _RiskResultDetails({required this.result, this.compact = false});

  final RiskRewardResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Calculation Result'),
        const SizedBox(height: 12),
        _HighlightMetric(
          asset: '11_green_position_bars.png',
          label: result.market == 'stocks'
              ? 'Recommended Shares'
              : result.market == 'binance_futures'
              ? 'Position Quantity'
              : 'Recommended Lot Size',
          value: _formatNumber(result.recommendedSize ?? result.positionUnits),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '12_red_risk_shield.png',
                label: 'Actual Risk',
                value: _money(result.actualRisk),
                color: TradeXColors.error,
              ),
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '13_green_reward_arrow.png',
                label: 'Potential Reward',
                value: result.potentialProfit == null
                    ? 'Not set'
                    : _money(result.potentialProfit),
                color: TradeXColors.success,
              ),
              if (result.requiredMargin != null)
                _MetricTile(
                  width: _metricWidth(constraints.maxWidth),
                  asset: '16_gold_coin_stacks.png',
                  label: 'Required Margin',
                  value: _money(result.requiredMargin),
                ),
              if (result.market == 'binance_futures' && result.leverage != null)
                _MetricTile(
                  width: _metricWidth(constraints.maxWidth),
                  asset: '16_gold_coin_stacks.png',
                  label: result.leverageAutoCalculated
                      ? 'Calculated Leverage'
                      : 'Leverage',
                  value: '${result.leverage}x',
                ),
              if (result.requiredInvestment != null)
                _MetricTile(
                  width: _metricWidth(constraints.maxWidth),
                  asset: '16_gold_coin_stacks.png',
                  label: 'Required Investment',
                  value: _money(result.requiredInvestment),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RatioBar(value: result.riskReward),
        if (!compact && result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final warning in result.warnings) _WarningLine(warning),
        ],
      ],
    ),
  );
}

class _DividendResultDetails extends StatelessWidget {
  const _DividendResultDetails({required this.result});

  final DividendResult result;

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Estimated Dividend Income'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '19_coins_tile.png',
                label: 'Annual Gross',
                value: _currency(result.annualGross, result.currency),
              ),
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '23_percent_tile.png',
                label: 'Dividend Yield',
                value: '${_formatNumber(result.yieldPercent)}%',
              ),
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '21_calendar_tile.png',
                label: 'Per Payment',
                value: _currency(result.grossPerPayment, result.currency),
              ),
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '24_dividend_hand_coin_tile.png',
                label: 'Estimated Net',
                value: _currency(result.annualNet, result.currency),
                color: TradeXColors.success,
              ),
              _MetricTile(
                width: _metricWidth(constraints.maxWidth),
                asset: '25_performance_bars_tile.png',
                label: 'Investment Value',
                value: _currency(result.investmentValue, result.currency),
              ),
            ],
          ),
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final warning in result.warnings) _WarningLine(warning),
        ],
      ],
    ),
  );
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({
    required this.asset,
    required this.label,
    required this.value,
  });

  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: TradeXColors.success.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TradeXColors.success.withValues(alpha: .7)),
    ),
    child: Row(
      children: [
        _AssetImage(asset, size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: TradeXColors.secondaryText),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.width,
    required this.asset,
    required this.label,
    required this.value,
    this.color = TradeXColors.goldBright,
  });

  final double width;
  final String asset;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: TradeXColors.surfaceRaised,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        _AssetImage(asset, size: 38),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: TradeXColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .55)),
    ),
    child: Row(
      children: [
        const _AssetImage('14_risk_reward_balance.png', size: 36),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Risk : Reward Ratio',
            style: TextStyle(color: TradeXColors.secondaryText),
          ),
        ),
        Text(
          value == null ? 'Not set' : '1 : ${value!.toStringAsFixed(2)}',
          style: TextStyle(
            color: value == null
                ? TradeXColors.secondaryText
                : TradeXColors.success,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ],
    ),
  );
}
