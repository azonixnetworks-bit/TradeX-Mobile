part of '../risk_reward_module.dart';

class DividendCalculatorScreen extends StatefulWidget {
  const DividendCalculatorScreen({super.key, this.initialStock});

  final StockInstrument? initialStock;

  @override
  State<DividendCalculatorScreen> createState() =>
      _DividendCalculatorScreenState();
}

class _DividendCalculatorScreenState extends State<DividendCalculatorScreen> {
  String? _symbol;
  final _shares = TextEditingController();
  final _price = TextEditingController();
  final _dps = TextEditingController();
  final _tax = TextEditingController(text: '0');
  final _fees = TextEditingController(text: '0');
  int _frequency = 4;
  bool _repeatAssumption = false;
  Map<String, dynamic>? _lastInput;

  @override
  void initState() {
    super.initState();
    _symbol = widget.initialStock?.symbol;
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final draft = await context.read<RiskRewardCubit>().repository.loadDraft(
      'dividend',
    );
    if (!mounted || draft == null) return;
    setState(() {
      _symbol = draft['symbol']?.toString() ?? _symbol;
      _shares.text = draft['shares']?.toString() ?? '';
      _price.text = draft['share_price']?.toString() ?? '';
      _dps.text = draft['dividend_per_share']?.toString() ?? '';
      _tax.text = draft['withholding_tax_percent']?.toString() ?? '0';
      _fees.text = draft['fees_per_payment']?.toString() ?? '0';
      _frequency =
          int.tryParse(draft['payments_per_year']?.toString() ?? '') ?? 4;
      _repeatAssumption = draft['repeated_payment_assumption'] == true;
    });
  }

  @override
  void dispose() {
    _shares.dispose();
    _price.dispose();
    _dps.dispose();
    _tax.dispose();
    _fees.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<RiskRewardCubit>().state.catalog!;
    final stocks = catalog.stocks;
    _symbol ??= stocks.isEmpty ? null : stocks.first.symbol;
    final selected = _findStock(stocks, _symbol);
    return _FeaturePage(
      child: _CalculatorCanvas(
        child: ListView(
          key: const ValueKey('dividend-calculator'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          children: [
            const _Eyebrow('INCOME PLANNER'),
            const SizedBox(height: 7),
            const _GradientTitle(first: 'Dividend', second: 'Calculator'),
            const SizedBox(height: 8),
            const _PageSubtitle(
              'Estimate dividend income using your existing manual assumptions.',
            ),
            const SizedBox(height: 18),
            _GoldCard(
              child: Row(
                children: [
                  _DividendStockBadge(symbol: selected?.symbol ?? '', size: 62),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StockDropdown(
                      value: _symbol,
                      stocks: stocks,
                      compact: true,
                      onChanged: (value) => setState(() => _symbol = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!catalog.dividendProviderAvailable)
              _StatusNotice(
                text: catalog.dividendMessage.isEmpty
                    ? 'Manual estimate mode. No verified dividend provider is connected.'
                    : catalog.dividendMessage,
              ),
            const SizedBox(height: 12),
            _GoldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Dividend assumptions'),
                  const SizedBox(height: 14),
                  _CalculatorField(
                    label: 'Number of Shares',
                    controller: _shares,
                    icon: Icons.hub_outlined,
                  ),
                  _CalculatorField(
                    label: 'Share Price (${selected?.currency ?? 'USD'})',
                    controller: _price,
                    icon: Icons.monetization_on_outlined,
                  ),
                  _CalculatorField(
                    label: 'Dividend per Share (DPS)',
                    controller: _dps,
                    icon: Icons.paid_outlined,
                  ),
                  _FrequencySelector(
                    value: _frequency,
                    onChanged: (value) => setState(() => _frequency = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GoldCard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _repeatAssumption,
                    activeTrackColor: TradeXColors.goldBright,
                    title: const Text('Repeat DPS for selected frequency'),
                    subtitle: const Text(
                      'Turn on only when you intentionally want a projected annual assumption.',
                      style: TextStyle(color: TradeXColors.secondaryText),
                    ),
                    onChanged: (value) =>
                        setState(() => _repeatAssumption = value),
                  ),
                  _CalculatorField(
                    label: 'Withholding Tax (%)',
                    controller: _tax,
                    icon: Icons.percent_rounded,
                  ),
                  _CalculatorField(
                    label: 'Fees per Payment',
                    controller: _fees,
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CalculateButton(
              onPressed: selected == null
                  ? null
                  : () => _calculate(context, selected),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: selected == null
                  ? null
                  : () =>
                        _open(context, DividendHistoryScreen(stock: selected)),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Dividend History & Calendar'),
            ),
            const SizedBox(height: 16),
            _CurrentDividendResult(input: _lastInput, onNewCalculation: _reset),
          ],
        ),
      ),
    );
  }

  Future<void> _calculate(BuildContext context, StockInstrument stock) async {
    final cubit = context.read<RiskRewardCubit>();
    final activity = ActivityTrackingScope.maybeOf(context);
    final input = <String, dynamic>{
      'symbol': stock.symbol,
      'company_name': stock.name,
      'currency': stock.currency,
      'shares': _shares.text.trim(),
      'share_price': _price.text.trim(),
      'dividend_per_share': _dps.text.trim(),
      'payments_per_year': _frequency,
      'withholding_tax_percent': _tax.text.trim(),
      'fees_per_payment': _fees.text.trim(),
      'repeated_payment_assumption': _repeatAssumption,
    };
    _lastInput = input;
    await cubit.repository.saveDraft('dividend', input);
    if (mounted) {
      final result = await cubit.calculateDividend(input);
      if (mounted && result != null) {
        activity?.track('calculator', 'calculator_used', subjectId: 'dividend');
      }
    }
  }

  void _reset() {
    _shares.clear();
    _price.clear();
    _dps.clear();
    _tax.text = '0';
    _fees.text = '0';
    setState(() {
      _frequency = 4;
      _repeatAssumption = false;
      _lastInput = null;
    });
    final cubit = context.read<RiskRewardCubit>()..clearResult();
    unawaited(cubit.repository.clearDraft('dividend'));
  }
}

class _DividendStockBadge extends StatelessWidget {
  const _DividendStockBadge({required this.symbol, this.size = 58});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cleanSymbol = symbol.trim();
    final label = cleanSymbol.isEmpty
        ? '—'
        : cleanSymbol
              .substring(0, cleanSymbol.length > 2 ? 2 : cleanSymbol.length)
              .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: palette.gold.withValues(alpha: .34)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.goldText,
          fontSize: size * .27,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
    );
  }
}
