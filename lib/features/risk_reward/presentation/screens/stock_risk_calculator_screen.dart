part of '../risk_reward_module.dart';

class StockRiskCalculatorScreen extends StatefulWidget {
  const StockRiskCalculatorScreen({super.key});

  @override
  State<StockRiskCalculatorScreen> createState() =>
      _StockRiskCalculatorScreenState();
}

class _StockRiskCalculatorScreenState extends State<StockRiskCalculatorScreen> {
  String _region = 'INTERNATIONAL';
  String? _symbol;
  final _manualSymbol = TextEditingController();
  final _entry = TextEditingController();
  final _stop = TextEditingController();
  final _risk = TextEditingController();
  final _target = TextEditingController();
  final _buyingPower = TextEditingController();
  final _feesPerShare = TextEditingController(text: '0');
  final _slippage = TextEditingController(text: '0');
  final _fxRate = TextEditingController();
  final _fxSource = TextEditingController();
  Map<String, dynamic>? _lastInput;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final draft = await context.read<RiskRewardCubit>().repository.loadDraft(
      'stocks',
    );
    if (!mounted || draft == null) return;
    setState(() {
      _region = draft['region']?.toString() ?? _region;
      _symbol = draft['symbol']?.toString();
      _manualSymbol.text = draft['symbol']?.toString() ?? '';
      _entry.text = draft['entry']?.toString() ?? '';
      _stop.text = draft['stop_loss']?.toString() ?? '';
      _risk.text = draft['risk_amount']?.toString() ?? '';
      _target.text = draft['take_profit']?.toString() ?? '';
      _buyingPower.text = draft['buying_power']?.toString() ?? '';
      _feesPerShare.text = draft['fees_per_share']?.toString() ?? '0';
      _slippage.text = draft['slippage_percent']?.toString() ?? '0';
      _fxRate.text = draft['instrument_to_usd_rate']?.toString() ?? '';
      _fxSource.text = draft['fx_rate_source']?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    _manualSymbol.dispose();
    _entry.dispose();
    _stop.dispose();
    _risk.dispose();
    _target.dispose();
    _buyingPower.dispose();
    _feesPerShare.dispose();
    _slippage.dispose();
    _fxRate.dispose();
    _fxSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stocks = context.watch<RiskRewardCubit>().state.catalog!.stocks;
    final visible = stocks
        .where((stock) => stock.region == _region)
        .toList(growable: false);
    _symbol ??= visible.isEmpty ? null : visible.first.symbol;
    if (_symbol != null && !visible.any((stock) => stock.symbol == _symbol)) {
      _symbol = visible.isEmpty ? null : visible.first.symbol;
    }
    final selected = _findStock(visible, _symbol);
    final isManual = _region == 'SRI_LANKA' || selected == null;
    final currency = isManual
        ? (_region == 'SRI_LANKA' ? 'LKR' : 'USD')
        : selected.currency;
    return _FeaturePage(
      child: _CalculatorCanvas(
        child: ListView(
          key: const ValueKey('stock-risk-calculator'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          children: [
            const _CalculatorHero(
              title: 'Stock Calculator',
              eyebrow: 'Stocks Risk Reward',
              subtitle: 'Calculate share quantity, risk and expected reward with current market metadata.',
            ),
            const SizedBox(height: 18),
            _SegmentedControl(
              values: const ['SRI_LANKA', 'INDIA', 'INTERNATIONAL'],
              labels: const ['Sri Lanka', 'India', 'International'],
              selected: _region,
              onSelected: (value) => setState(() {
                _region = value;
                _symbol = null;
                context.read<RiskRewardCubit>().clearResult();
              }),
            ),
            const SizedBox(height: 16),
            if (isManual)
              _CalculatorField(
                label: 'Symbol / Company (Manual)',
                controller: _manualSymbol,
                icon: Icons.search_rounded,
                numeric: false,
              )
            else
              _StockSearchField(
                key: ValueKey(_region),
                selected: selected,
                stocks: visible,
                onSelected: (value) => setState(() => _symbol = value.symbol),
              ),
            if (_region == 'SRI_LANKA')
              const _StatusNotice(
                text: 'CSE live quotes are not connected. Enter prices manually; no live price is simulated.',
              ),
            const SizedBox(height: 12),
            const _TradeSideControl(selected: 'BUY'),
            const SizedBox(height: 14),
            _CalculatorField(
              label: 'Entry Price ($currency)',
              controller: _entry,
              icon: Icons.login,
            ),
            _CalculatorField(
              label: 'Stop Loss Price ($currency)',
              controller: _stop,
              icon: Icons.shield_outlined,
            ),
            _CalculatorField(
              label: 'Risk Amount (USD)',
              controller: _risk,
              icon: Icons.savings_outlined,
            ),
            _CalculatorField(
              label: 'Take Profit Price (Optional)',
              controller: _target,
              icon: Icons.track_changes,
            ),
            _CalculatorField(
              label: 'Buying Power (Optional)',
              controller: _buyingPower,
              icon: Icons.account_balance_wallet_outlined,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Fees & Slippage (Optional)'),
              children: [
                _CalculatorField(
                  label: 'Fees per Share',
                  controller: _feesPerShare,
                  icon: Icons.receipt_long_outlined,
                ),
                _CalculatorField(
                  label: 'Slippage (%)',
                  controller: _slippage,
                  icon: Icons.percent_rounded,
                ),
              ],
            ),
            if (currency != 'USD') ...[
              _CalculatorField(
                label: '$currency to USD Rate',
                controller: _fxRate,
                icon: Icons.currency_exchange_rounded,
              ),
              _CalculatorField(
                label: 'FX Rate Source',
                controller: _fxSource,
                icon: Icons.source_outlined,
                numeric: false,
              ),
            ],
            _CalculateButton(
              onPressed: () =>
                  _calculate(context, selected: selected, currency: currency),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _open(
                context,
                DividendCalculatorScreen(initialStock: selected),
              ),
              icon: const Icon(Icons.savings_rounded),
              label: const Text('Open Dividend Calculator'),
            ),
            const SizedBox(height: 16),
            _CurrentResult(input: _lastInput, onNewCalculation: _reset),
          ],
        ),
      ),
    );
  }

  Future<void> _calculate(
    BuildContext context, {
    required StockInstrument? selected,
    required String currency,
  }) async {
    final cubit = context.read<RiskRewardCubit>();
    final activity = ActivityTrackingScope.maybeOf(context);
    final symbol = selected?.symbol ?? _manualSymbol.text.trim().toUpperCase();
    final input = <String, dynamic>{
      'market': 'stocks',
      'symbol': symbol,
      'company_name': selected?.name ?? symbol,
      'region': _region,
      'exchange':
          selected?.exchange ?? (_region == 'SRI_LANKA' ? 'CSE' : 'MANUAL'),
      'currency': currency,
      'data_mode': selected?.dataMode ?? 'MANUAL',
      'side': 'BUY',
      'entry': _entry.text.trim(),
      'stop_loss': _stop.text.trim(),
      'risk_amount': _risk.text.trim(),
      if (_target.text.trim().isNotEmpty) 'take_profit': _target.text.trim(),
      if (_buyingPower.text.trim().isNotEmpty)
        'buying_power': _buyingPower.text.trim(),
      'fees_per_share': _feesPerShare.text.trim(),
      'slippage_percent': _slippage.text.trim(),
      if (currency != 'USD') ...{
        'instrument_to_usd_rate': _fxRate.text.trim(),
        'fx_rate_source': _fxSource.text.trim(),
        'fx_rate_observed_at': DateTime.now().toUtc().toIso8601String(),
      },
      'fractional_enabled': false,
      'short_selling_supported': false,
    };
    _lastInput = input;
    await cubit.repository.saveDraft('stocks', input);
    if (mounted) {
      final result = await cubit.calculate(input);
      if (mounted && result != null) {
        activity?.track('calculator', 'calculator_used', subjectId: 'stocks');
      }
    }
  }

  void _reset() {
    for (final controller in <TextEditingController>[
      _manualSymbol,
      _entry,
      _stop,
      _risk,
      _target,
      _buyingPower,
      _fxRate,
      _fxSource,
    ]) {
      controller.clear();
    }
    _feesPerShare.text = '0';
    _slippage.text = '0';
    setState(() => _lastInput = null);
    final cubit = context.read<RiskRewardCubit>()..clearResult();
    unawaited(cubit.repository.clearDraft('stocks'));
  }
}
