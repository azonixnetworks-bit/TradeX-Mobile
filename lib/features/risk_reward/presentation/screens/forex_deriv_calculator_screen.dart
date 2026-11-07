part of '../risk_reward_module.dart';

class ForexDerivCalculatorScreen extends StatefulWidget {
  const ForexDerivCalculatorScreen({super.key, this.initialMarket = 'forex'});

  final String initialMarket;

  @override
  State<ForexDerivCalculatorScreen> createState() =>
      _ForexDerivCalculatorScreenState();
}

class _ForexDerivCalculatorScreenState
    extends State<ForexDerivCalculatorScreen> {
  late String _market;
  String _side = 'BUY';
  String? _symbol;
  final _entry = TextEditingController();
  final _stop = TextEditingController();
  final _risk = TextEditingController();
  final _target = TextEditingController();
  bool _quoteLoading = false;
  String? _quoteError;
  RiskRewardQuote? _liveQuote;
  int _quoteRequest = 0;
  Map<String, dynamic>? _lastInput;

  @override
  void initState() {
    super.initState();
    _market = widget.initialMarket;
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final draft = await context.read<RiskRewardCubit>().repository.loadDraft(
      'forex_deriv',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<RiskRewardCubit>().state.catalog!;
    final market = catalog.markets[_market];
    final instruments = market?.instruments ?? const <RiskRewardInstrument>[];
    if (_symbol != null && !instruments.any((item) => item.symbol == _symbol)) {
      _symbol = null;
    }
    return _FeaturePage(
      child: _CalculatorCanvas(
        child: ListView(
          key: const ValueKey('forex-deriv-calculator'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          children: [
            const _CalculatorHero(
              title: 'Forex Calculator',
              eyebrow: 'Forex & Deriv',
              subtitle: 'Calculate position size and risk while preserving live Forex and Deriv contract rules.',
            ),
            const SizedBox(height: 20),
            _SegmentedControl(
              values: const ['forex', 'deriv'],
              labels: const ['Forex', 'Deriv'],
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
              key: ValueKey('symbol-search-$_market'),
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
              label: 'Entry Price (Live, editable)',
              controller: _entry,
              icon: Icons.login,
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
    };
    _lastInput = input;
    await cubit.repository.saveDraft('forex_deriv', input);
    if (mounted) {
      final result = await cubit.calculate(input);
      if (mounted && result != null) {
        activity?.track(
          'calculator',
          'calculator_used',
          subjectId: 'forex_deriv',
        );
      }
    }
  }

  void _reset() {
    _entry.clear();
    _stop.clear();
    _risk.clear();
    _target.clear();
    setState(() => _lastInput = null);
    final cubit = context.read<RiskRewardCubit>()..clearResult();
    unawaited(cubit.repository.clearDraft('forex_deriv'));
  }
}
