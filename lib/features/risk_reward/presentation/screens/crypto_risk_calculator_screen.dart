part of '../risk_reward_module.dart';

class CryptoRiskCalculatorScreen extends StatefulWidget {
  const CryptoRiskCalculatorScreen({super.key});

  @override
  State<CryptoRiskCalculatorScreen> createState() =>
      _CryptoRiskCalculatorScreenState();
}

class _CryptoRiskCalculatorScreenState
    extends State<CryptoRiskCalculatorScreen> {
  String _market = 'binance_futures';
  String _side = 'BUY';
  String? _symbol;
  final _entry = TextEditingController();
  final _stop = TextEditingController();
  final _risk = TextEditingController();
  final _target = TextEditingController();
  final _entryFee = TextEditingController(text: '0');
  final _exitFee = TextEditingController(text: '0');
  final _slippage = TextEditingController(text: '0');
  final _fundingRate = TextEditingController(text: '0');
  final _fundingIntervals = TextEditingController(text: '0');
  final _maintenanceRate = TextEditingController();
  final _maintenanceAmount = TextEditingController();
  final _walletBalance = TextEditingController();
  bool _quoteLoading = false;
  String? _quoteError;
  RiskRewardQuote? _liveQuote;
  int _quoteRequest = 0;
  Map<String, dynamic>? _lastInput;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final draft = await context.read<RiskRewardCubit>().repository.loadDraft(
      'crypto',
    );
    if (!mounted || draft == null) return;
    setState(() {
      _market = draft['market']?.toString() ?? _market;
      _side = draft['side']?.toString() ?? _side;
      _symbol = draft['symbol']?.toString();
      _entry.text = draft['entry']?.toString() ?? '';
      _stop.text = draft['stop_loss']?.toString() ?? '';
      _risk.text = draft['risk_amount']?.toString() ?? '';
      _target.text = draft['take_profit']?.toString() ?? '';
      _entryFee.text = draft['entry_fee_rate_percent']?.toString() ?? '0';
      _exitFee.text = draft['exit_fee_rate_percent']?.toString() ?? '0';
      _slippage.text = draft['slippage_percent']?.toString() ?? '0';
      _fundingRate.text = draft['funding_rate_percent']?.toString() ?? '0';
      _fundingIntervals.text = draft['funding_intervals']?.toString() ?? '0';
      _maintenanceRate.text =
          draft['maintenance_margin_rate_percent']?.toString() ?? '';
      _maintenanceAmount.text = draft['maintenance_amount']?.toString() ?? '';
      _walletBalance.text =
          draft['liquidation_wallet_balance']?.toString() ?? '';
    });
    if (_symbol != null) {
      unawaited(_loadLivePrice(_symbol!));
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _stop.dispose();
    _risk.dispose();
    _target.dispose();
    _entryFee.dispose();
    _exitFee.dispose();
    _slippage.dispose();
    _fundingRate.dispose();
    _fundingIntervals.dispose();
    _maintenanceRate.dispose();
    _maintenanceAmount.dispose();
    _walletBalance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<RiskRewardCubit>().state.catalog!;
    final instruments =
        catalog.markets[_market]?.instruments ?? const <RiskRewardInstrument>[];
    if (_symbol != null && !instruments.any((item) => item.symbol == _symbol)) {
      _symbol = null;
    }
    return _FeaturePage(
      child: _CalculatorCanvas(
        child: ListView(
          key: const ValueKey('crypto-risk-calculator'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          children: [
            const _CalculatorHero(
              title: 'Crypto Calculator',
              eyebrow: 'Crypto',
              subtitle: 'Calculate crypto trade size, risk and liquidation data using current contract rules.',
            ),
            const SizedBox(height: 20),
            _SegmentedControl(
              values: const ['binance_futures', 'crypto'],
              labels: const ['Binance Futures', 'Crypto CFD'],
              selected: _market,
              onSelected: (value) => setState(() {
                _market = value;
                _symbol = null;
                _entry.clear();
                _quoteRequest++;
                _quoteLoading = false;
                _quoteError = null;
                _liveQuote = null;
                context.read<RiskRewardCubit>().clearResult();
              }),
            ),
            const SizedBox(height: 16),
            _InstrumentSearchField(
              key: ValueKey('crypto-symbol-search-$_market'),
              selected: _instrumentBySymbol(instruments, _symbol),
              instruments: instruments,
              onQueryChanged: () {
                if (_symbol == null) return;
                setState(() {
                  _symbol = null;
                  _quoteRequest++;
                  _quoteLoading = false;
                  _quoteError = null;
                  _liveQuote = null;
                });
              },
              onSelected: (instrument) {
                setState(() {
                  _symbol = instrument.symbol;
                  _quoteError = null;
                });
                unawaited(_loadLivePrice(instrument.symbol));
              },
            ),
            const SizedBox(height: 14),
            _TradeSideControl(
              selected: _side,
              onSelected: (value) {
                setState(() => _side = value);
                if (_symbol != null) unawaited(_loadLivePrice(_symbol!));
              },
            ),
            const SizedBox(height: 14),
            _CalculatorField(
              label: 'Entry Price',
              controller: _entry,
              icon: Icons.login,
              onChanged: (_) => setState(() {}),
            ),
            _LivePriceStatus(
              loading: _quoteLoading,
              quote: _liveQuote,
              error: _quoteError,
              onRefresh: _symbol == null
                  ? null
                  : () => _loadLivePrice(_symbol!),
            ),
            const SizedBox(height: 12),
            _CalculatorField(
              label: 'Stop Loss Price',
              controller: _stop,
              icon: Icons.shield_outlined,
              onChanged: (_) => setState(() {}),
            ),
            if (_market == 'binance_futures') ...[
              _AutoLeverageCard(
                leverage: _calculatedLeverage,
                stopDistancePercent: _stopDistancePercent,
              ),
              const SizedBox(height: 12),
            ],
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
            if (_market == 'binance_futures') ...[
              const SizedBox(height: 10),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Costs & Liquidation Inputs (Optional)'),
                subtitle: const Text(
                  'Use current Binance tier and account values.',
                  style: TextStyle(color: TradeXColors.secondaryText),
                ),
                children: [
                  _CalculatorField(
                    label: 'Entry Fee Rate (%)',
                    controller: _entryFee,
                    icon: Icons.receipt_long_outlined,
                  ),
                  _CalculatorField(
                    label: 'Exit Fee Rate (%)',
                    controller: _exitFee,
                    icon: Icons.receipt_long_outlined,
                  ),
                  _CalculatorField(
                    label: 'Slippage (%)',
                    controller: _slippage,
                    icon: Icons.percent_rounded,
                  ),
                  _CalculatorField(
                    label: 'Funding Rate (%)',
                    controller: _fundingRate,
                    icon: Icons.currency_exchange_rounded,
                  ),
                  _CalculatorField(
                    label: 'Funding Intervals',
                    controller: _fundingIntervals,
                    icon: Icons.schedule_rounded,
                  ),
                  _CalculatorField(
                    label: 'Maintenance Margin Rate (%)',
                    controller: _maintenanceRate,
                    icon: Icons.security_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  _CalculatorField(
                    label: 'Maintenance Amount (USDT)',
                    controller: _maintenanceAmount,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _CalculatorField(
                    label: 'Isolated Wallet Balance (USDT)',
                    controller: _walletBalance,
                    icon: Icons.wallet_outlined,
                  ),
                ],
              ),
            ] else
              const _StatusNotice(
                text: 'Margin is shown only when the selected broker contract includes a verified margin specification.',
              ),
            const SizedBox(height: 12),
            _CalculateButton(
              onPressed: _symbol == null ? null : () => _calculate(context),
            ),
            const SizedBox(height: 16),
            _CurrentResult(input: _lastInput, onNewCalculation: _reset),
          ],
        ),
      ),
    );
  }

  Future<void> _calculate(BuildContext context) async {
    final cubit = context.read<RiskRewardCubit>();
    final activity = ActivityTrackingScope.maybeOf(context);
    final input = <String, dynamic>{
      'market': _market,
      'symbol': _symbol,
      'side': _side,
      'entry': _entry.text.trim(),
      'stop_loss': _stop.text.trim(),
      'risk_amount': _risk.text.trim(),
      if (_target.text.trim().isNotEmpty) 'take_profit': _target.text.trim(),
      if (_market == 'binance_futures') ...{
        'calculation_mode': 'RISK_BASED',
        'margin_mode': 'ISOLATED',
        'entry_fee_rate_percent': _entryFee.text.trim(),
        'exit_fee_rate_percent': _exitFee.text.trim(),
        'slippage_percent': _slippage.text.trim(),
        'funding_rate_percent': _fundingRate.text.trim(),
        'funding_intervals': _fundingIntervals.text.trim(),
        if (_maintenanceRate.text.trim().isNotEmpty)
          'maintenance_margin_rate_percent': _maintenanceRate.text.trim(),
        if (_maintenanceAmount.text.trim().isNotEmpty)
          'maintenance_amount': _maintenanceAmount.text.trim(),
        if (_walletBalance.text.trim().isNotEmpty)
          'liquidation_wallet_balance': _walletBalance.text.trim(),
      },
    };
    _lastInput = input;
    await cubit.repository.saveDraft('crypto', input);
    if (mounted) {
      final result = await cubit.calculate(input);
      if (mounted && result != null) {
        activity?.track('calculator', 'calculator_used', subjectId: 'crypto');
      }
    }
  }

  Future<void> _loadLivePrice(String symbol) async {
    final request = ++_quoteRequest;
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });

    try {
      final quote = await context.read<RiskRewardCubit>().repository.quote(
        market: _market,
        symbol: symbol,
        side: _side,
      );
      if (!mounted || request != _quoteRequest || _symbol != symbol) return;
      _entry.text = quote.displayPrice;
      setState(() {
        _quoteLoading = false;
        _liveQuote = quote;
      });
    } catch (_) {
      if (!mounted || request != _quoteRequest || _symbol != symbol) return;
      setState(() {
        _quoteLoading = false;
        _liveQuote = null;
        _quoteError =
            'Live price unavailable. You can enter the price manually.';
      });
    }
  }

  double? get _stopDistancePercent {
    final entry = double.tryParse(_entry.text.trim());
    final stop = double.tryParse(_stop.text.trim());
    if (entry == null || stop == null || entry <= 0 || stop <= 0) return null;
    if (_side == 'BUY' ? stop >= entry : stop <= entry) return null;
    return ((entry - stop).abs() / entry) * 100;
  }

  int? get _calculatedLeverage {
    final distancePercent = _stopDistancePercent;
    if (distancePercent == null) return null;
    final suppliedMaintenanceMargin = double.tryParse(
      _maintenanceRate.text.trim(),
    );
    final maintenanceMarginPercent =
        suppliedMaintenanceMargin != null && suppliedMaintenanceMargin > 0
        ? suppliedMaintenanceMargin
        : 0.5;
    const liquidationBufferPercent = 0.5;
    final protectedDistance =
        (distancePercent +
            maintenanceMarginPercent +
            liquidationBufferPercent) /
        100;
    if (protectedDistance <= 0) return null;
    return (1 / protectedDistance).floor().clamp(1, 125).toInt();
  }

  void _reset() {
    for (final controller in <TextEditingController>[
      _entry,
      _stop,
      _risk,
      _target,
      _maintenanceRate,
      _maintenanceAmount,
      _walletBalance,
    ]) {
      controller.clear();
    }
    _entryFee.text = '0';
    _exitFee.text = '0';
    _slippage.text = '0';
    _fundingRate.text = '0';
    _fundingIntervals.text = '0';
    setState(() => _lastInput = null);
    final cubit = context.read<RiskRewardCubit>()..clearResult();
    unawaited(cubit.repository.clearDraft('crypto'));
  }
}
