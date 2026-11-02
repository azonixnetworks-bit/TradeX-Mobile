import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/activity/activity_tracking_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/risk_reward_repository.dart';
import '../models/risk_reward_models.dart';
import 'bloc/risk_reward_cubit.dart';

const _assetRoot = 'assets/risk_reward';

class RiskRewardHomeScreen extends StatefulWidget {
  const RiskRewardHomeScreen({super.key, required this.repository});

  final RiskRewardDataSource repository;

  @override
  State<RiskRewardHomeScreen> createState() => _RiskRewardHomeScreenState();
}

class _RiskRewardHomeScreenState extends State<RiskRewardHomeScreen>
    with WidgetsBindingObserver {
  late final RiskRewardCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = RiskRewardCubit(widget.repository)..initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_cubit.initialize(forceRefresh: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: _FeaturePage(
      child: BlocBuilder<RiskRewardCubit, RiskRewardState>(
        builder: (context, state) {
          if (state.status == RiskRewardStatus.loading &&
              state.catalog == null) {
            return const _CenteredLoader(label: 'Loading calculator markets…');
          }
          if (state.catalog == null) {
            return _RetryState(
              message: state.error ?? 'Calculator markets are unavailable.',
              onRetry: () => context.read<RiskRewardCubit>().initialize(
                forceRefresh: true,
              ),
            );
          }
          return _CalculatorDashboard(state: state);
        },
      ),
    ),
  );
}

class _CalculatorDashboard extends StatelessWidget {
  const _CalculatorDashboard({required this.state});

  final RiskRewardState state;

  @override
  Widget build(BuildContext context) {
    final catalog = state.catalog!;
    return ListView(
      key: const ValueKey('risk-reward-dashboard'),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
      children: [
        const _Eyebrow('TRADING TOOLS'),
        const SizedBox(height: 8),
        const _GradientTitle(first: 'Risk Reward', second: 'Calculator'),
        const SizedBox(height: 12),
        const Text(
          'Plan position size, margin and reward across supported markets before you trade.',
          style: TextStyle(
            color: TradeXColors.secondaryText,
            height: 1.45,
            fontSize: 15,
          ),
        ),
        if (catalog.isOffline || catalog.isStale) ...[
          const SizedBox(height: 14),
          _StatusNotice(
            text: catalog.isStale
                ? 'Saved market specifications are shown. Refresh before calculating.'
                : 'Offline catalog loaded. New calculations still require the server.',
          ),
        ],
        const SizedBox(height: 22),
        const _HeroCard(),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 620
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _DashboardMarketCard(
                  width: width,
                  asset: '02_forex_candlesticks.png',
                  title: 'Forex',
                  subtitle: 'Lot Size\nRisk & Reward',
                  onTap: () => _open(
                    context,
                    const ForexDerivCalculatorScreen(initialMarket: 'forex'),
                  ),
                ),
                _DashboardMarketCard(
                  width: width,
                  asset: '03_deriv_styled_symbol.png',
                  title: 'Deriv',
                  subtitle: 'Lot Size\nRisk & Reward',
                  onTap: () => _open(
                    context,
                    const ForexDerivCalculatorScreen(initialMarket: 'deriv'),
                  ),
                ),
                _DashboardMarketCard(
                  width: width,
                  asset: '04_bitcoin_glowing_coin.png',
                  title: 'Crypto',
                  subtitle: 'Futures + CFD\nMargin & Quantity',
                  onTap: () =>
                      _open(context, const CryptoRiskCalculatorScreen()),
                ),
                _DashboardMarketCard(
                  width: width,
                  asset: '05_gold_growth_bars.png',
                  title: 'Stocks',
                  subtitle: 'Shares, Dividends\nRisk & Reward',
                  onTap: () =>
                      _open(context, const StockRiskCalculatorScreen()),
                ),
              ],
            );
          },
        ),
        if (state.saved.isNotEmpty) ...[
          const SizedBox(height: 26),
          const _SectionTitle('Saved Calculations'),
          const SizedBox(height: 10),
          for (final item in state.saved.take(5))
            _SavedCalculationTile(item: item),
        ],
        if (catalog.disclaimer.isNotEmpty) ...[
          const SizedBox(height: 18),
          _StatusNotice(text: catalog.disclaimer, icon: Icons.info_outline),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trade Smarter —',
                style: TextStyle(
                  color: TradeXColors.goldBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Manage Your Risk',
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Use verified specifications and server-side calculations to plan with confidence.',
                style: TextStyle(
                  color: TradeXColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const _AssetImage('01_growth_arrow_chart.png', size: 108),
      ],
    ),
  );
}

class _DashboardMarketCard extends StatelessWidget {
  const _DashboardMarketCard({
    required this.width,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final String asset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: _GoldCard(
      onTap: onTap,
      child: Row(
        children: [
          _AssetImage(asset, size: 74),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TradeXColors.goldBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: TradeXColors.goldBright,
          ),
        ],
      ),
    ),
  );
}

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
      child: ListView(
        key: const ValueKey('forex-deriv-calculator'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          const _GradientTitle(first: 'Forex & Deriv', second: 'Calculator'),
          const SizedBox(height: 8),
          const _PageSubtitle(
            'Calculate a risk-matched lot size before you trade.',
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
            onRefresh: _symbol == null ? null : () => _loadLivePrice(_symbol!),
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
        ActivityTrackingScope.maybeOf(context)?.track(
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
      child: ListView(
        key: const ValueKey('crypto-risk-calculator'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          const _GradientTitle(first: 'Crypto', second: 'Calculator'),
          const SizedBox(height: 8),
          const _PageSubtitle(
            'Futures and CFD position sizing with real contract rules.',
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
            onRefresh: _symbol == null ? null : () => _loadLivePrice(_symbol!),
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
    );
  }

  Future<void> _calculate(BuildContext context) async {
    final cubit = context.read<RiskRewardCubit>();
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
        ActivityTrackingScope.maybeOf(context)?.track(
          'calculator',
          'calculator_used',
          subjectId: 'crypto',
        );
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
      child: ListView(
        key: const ValueKey('stock-risk-calculator'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          const _GradientTitle(
            first: 'Stocks Risk Reward',
            second: 'Calculator',
          ),
          const SizedBox(height: 8),
          const _PageSubtitle(
            'Risk-based whole-share sizing with explicit FX provenance.',
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
    );
  }

  Future<void> _calculate(
    BuildContext context, {
    required StockInstrument? selected,
    required String currency,
  }) async {
    final cubit = context.read<RiskRewardCubit>();
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
        ActivityTrackingScope.maybeOf(context)?.track(
          'calculator',
          'calculator_used',
          subjectId: 'stocks',
        );
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
      child: ListView(
        key: const ValueKey('dividend-calculator'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          const _GradientTitle(first: 'Dividend', second: 'Calculator'),
          const SizedBox(height: 8),
          const _PageSubtitle(
            'Estimate income using explicit manual assumptions.',
          ),
          const SizedBox(height: 18),
          _GoldCard(
            child: Row(
              children: [
                const _AssetImage('17_apple_logo_tile.png', size: 62),
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
                : () => _open(context, DividendHistoryScreen(stock: selected)),
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Dividend History & Calendar'),
          ),
          const SizedBox(height: 16),
          _CurrentDividendResult(input: _lastInput, onNewCalculation: _reset),
        ],
      ),
    );
  }

  Future<void> _calculate(BuildContext context, StockInstrument stock) async {
    final cubit = context.read<RiskRewardCubit>();
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
        ActivityTrackingScope.maybeOf(context)?.track(
          'calculator',
          'calculator_used',
          subjectId: 'dividend',
        );
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

class DividendHistoryScreen extends StatefulWidget {
  const DividendHistoryScreen({super.key, required this.stock});

  final StockInstrument stock;

  @override
  State<DividendHistoryScreen> createState() => _DividendHistoryScreenState();
}

class _DividendHistoryScreenState extends State<DividendHistoryScreen> {
  late Future<DividendHistory> _request;

  @override
  void initState() {
    super.initState();
    _request = context.read<RiskRewardCubit>().repository.dividendHistory(
      widget.stock.symbol,
    );
  }

  @override
  Widget build(BuildContext context) => _FeaturePage(
    child: FutureBuilder<DividendHistory>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _CenteredLoader(label: 'Loading dividend history…');
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _RetryState(
            message: 'Dividend history is unavailable.',
            onRetry: () => setState(() {
              _request = context
                  .read<RiskRewardCubit>()
                  .repository
                  .dividendHistory(widget.stock.symbol);
            }),
          );
        }
        final data = snapshot.data!;
        return ListView(
          key: const ValueKey('dividend-history-calendar'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          children: [
            const _GradientTitle(
              first: 'Dividend History',
              second: '& Calendar',
            ),
            const SizedBox(height: 8),
            const _PageSubtitle(
              'Verified dates and payouts only — no invented future declarations.',
            ),
            const SizedBox(height: 18),
            _GoldCard(
              child: Row(
                children: [
                  const _AssetImage('21_calendar_tile.png', size: 66),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.symbol,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          data.companyName,
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!data.providerAvailable)
              _EmptyProviderState(message: data.message)
            else ...[
              if (data.upcoming != null)
                _JsonDetailCard(
                  title: 'Upcoming Dividend',
                  data: data.upcoming!,
                ),
              const SizedBox(height: 14),
              if (data.history.isEmpty)
                const _EmptyProviderState(
                  message: 'No verified dividend history is available.',
                )
              else
                for (final item in data.history)
                  _JsonDetailCard(title: 'Dividend Payment', data: item),
            ],
          ],
        );
      },
    ),
  );
}

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

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: SafeArea(child: child),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.goldBright,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 3,
    ),
  );
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.first, required this.second});

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 2,
    children: [
      Text(
        first,
        style: const TextStyle(
          color: TradeXColors.primaryText,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [TradeXColors.goldBright, Color(0xFFFFE29A)],
        ).createShader(bounds),
        child: Text(
          second,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ),
    ],
  );
}

class _PageSubtitle extends StatelessWidget {
  const _PageSubtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.secondaryText,
      fontSize: 14,
      height: 1.45,
    ),
  );
}

class _GoldCard extends StatelessWidget {
  const _GoldCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15160F), TradeXColors.surface, Color(0xFF0A0D0C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TradeXColors.goldSoft.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(
            color: TradeXColors.gold.withValues(alpha: .08),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _AssetImage extends StatelessWidget {
  const _AssetImage(this.name, {required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    '$_assetRoot/$name',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => SizedBox.square(
      dimension: size,
      child: const Icon(
        Icons.calculate_rounded,
        color: TradeXColors.goldBright,
      ),
    ),
  );
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final itemWidth = values.length <= 2
          ? (constraints.maxWidth - 8) / values.length
          : (constraints.maxWidth - 16) / values.length;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(values.length, (index) {
          final active = values[index] == selected;
          return SizedBox(
            width: itemWidth,
            child: Semantics(
              selected: active,
              button: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [TradeXColors.goldBright, Color(0xFFE0A51C)],
                        )
                      : null,
                  color: active ? null : TradeXColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: active
                        ? TradeXColors.goldBright
                        : TradeXColors.borderStrong,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => onSelected(values[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 13,
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: active ? Colors.black : TradeXColors.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: values.length > 2 ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    },
  );
}

RiskRewardInstrument? _instrumentBySymbol(
  List<RiskRewardInstrument> instruments,
  String? symbol,
) {
  if (symbol == null) return null;
  for (final instrument in instruments) {
    if (instrument.symbol == symbol) return instrument;
  }
  return null;
}

class _InstrumentSearchField extends StatefulWidget {
  const _InstrumentSearchField({
    super.key,
    required this.selected,
    required this.instruments,
    required this.onQueryChanged,
    required this.onSelected,
  });

  final RiskRewardInstrument? selected;
  final List<RiskRewardInstrument> instruments;
  final VoidCallback onQueryChanged;
  final ValueChanged<RiskRewardInstrument> onSelected;

  @override
  State<_InstrumentSearchField> createState() => _InstrumentSearchFieldState();
}

class _InstrumentSearchFieldState extends State<_InstrumentSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selected?.symbol ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _InstrumentSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selected?.symbol ?? '';
    if (next.isNotEmpty && _controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  List<RiskRewardInstrument> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    if (!_focusNode.hasFocus || query.isEmpty) {
      return const <RiskRewardInstrument>[];
    }
    return widget.instruments
        .where(
          (item) =>
              item.symbol.toLowerCase().contains(query) ||
              item.name.toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('forex-deriv-symbol-search'),
          controller: _controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) {
            widget.onQueryChanged();
            setState(() {});
          },
          decoration:
              _inputDecoration(
                'Type symbol or market name',
                Icons.search_rounded,
              ).copyWith(
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear symbol',
                        onPressed: () {
                          _controller.clear();
                          widget.onQueryChanged();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: suggestions.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  key: ValueKey(_controller.text.toLowerCase()),
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 288),
                  decoration: BoxDecoration(
                    color: TradeXColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TradeXColors.borderStrong),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          key: ValueKey('symbol-suggestion-${item.symbol}'),
                          dense: true,
                          leading: const Icon(
                            Icons.show_chart_rounded,
                            color: TradeXColors.gold,
                          ),
                          title: Text(
                            item.symbol,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _controller.value = TextEditingValue(
                              text: item.symbol,
                              selection: TextSelection.collapsed(
                                offset: item.symbol.length,
                              ),
                            );
                            _focusNode.unfocus();
                            widget.onSelected(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _LivePriceStatus extends StatelessWidget {
  const _LivePriceStatus({
    required this.loading,
    required this.quote,
    required this.error,
    required this.onRefresh,
  });

  final bool loading;
  final RiskRewardQuote? quote;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = error != null
        ? TradeXColors.error
        : quote != null
        ? TradeXColors.success
        : TradeXColors.secondaryText;
    final message = loading
        ? 'Loading current market price…'
        : error ??
              (quote == null
                  ? 'Select a symbol to load its current price.'
                  : 'Live ${quote!.symbol}: ${quote!.displayPrice} • Entry price remains editable');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              error != null
                  ? Icons.cloud_off_rounded
                  : Icons.currency_exchange_rounded,
              size: 18,
              color: color,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!loading && onRefresh != null)
            IconButton(
              tooltip: 'Refresh live price',
              visualDensity: VisualDensity.compact,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 19),
            ),
        ],
      ),
    );
  }
}

class _StockDropdown extends StatelessWidget {
  const _StockDropdown({
    required this.value,
    required this.stocks,
    required this.onChanged,
    this.compact = false,
  });

  final String? value;
  final List<StockInstrument> stocks;
  final ValueChanged<String?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: stocks.any((item) => item.symbol == value) ? value : null,
    isExpanded: true,
    dropdownColor: TradeXColors.surfaceRaised,
    decoration: _inputDecoration(
      compact ? 'Stock' : 'Stock / Symbol',
      Icons.business_rounded,
    ),
    items: stocks
        .map(
          (item) => DropdownMenuItem(
            value: item.symbol,
            child: Text(
              '${item.symbol}  •  ${item.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(growable: false),
    onChanged: stocks.isEmpty ? null : onChanged,
  );
}

class _StockSearchField extends StatelessWidget {
  const _StockSearchField({
    super.key,
    required this.selected,
    required this.stocks,
    required this.onSelected,
  });

  final StockInstrument? selected;
  final List<StockInstrument> stocks;
  final ValueChanged<StockInstrument> onSelected;

  @override
  Widget build(BuildContext context) => Autocomplete<StockInstrument>(
    initialValue: TextEditingValue(
      text: selected == null ? '' : '${selected!.symbol} • ${selected!.name}',
    ),
    displayStringForOption: (stock) => '${stock.symbol} • ${stock.name}',
    optionsBuilder: (value) {
      final query = value.text.trim().toLowerCase();
      if (query.isEmpty) return stocks;
      return stocks.where(
        (stock) =>
            stock.symbol.toLowerCase().contains(query) ||
            stock.name.toLowerCase().contains(query),
      );
    },
    onSelected: onSelected,
    fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmitted(),
          decoration: _inputDecoration(
            'Search symbol or company',
            Icons.search_rounded,
          ),
        ),
    optionsViewBuilder: (context, select, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: TradeXColors.surfaceRaised,
        elevation: 10,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 260),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final item = options.elementAt(index);
              return ListTile(
                dense: true,
                title: Text(item.symbol),
                subtitle: Text(item.name),
                onTap: () => select(item),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _TradeSideControl extends StatelessWidget {
  const _TradeSideControl({required this.selected, this.onSelected});

  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _sideButton('BUY', TradeXColors.success)),
      const SizedBox(width: 10),
      Expanded(child: _sideButton('SELL', TradeXColors.error)),
    ],
  );

  Widget _sideButton(String value, Color color) {
    final active = selected == value;
    final enabled = onSelected != null || active;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: .15)
            : TradeXColors.surfaceRaised,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: active ? color : TradeXColors.borderStrong),
      ),
      child: InkWell(
        onTap: enabled && onSelected != null ? () => onSelected!(value) : null,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? color : TradeXColors.tertiaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorField extends StatelessWidget {
  const _CalculatorField({
    required this.label,
    required this.controller,
    required this.icon,
    this.numeric = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool numeric;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: false)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      onChanged: onChanged,
      style: const TextStyle(
        color: TradeXColors.primaryText,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(label, icon),
    ),
  );
}

class _CalculateButton extends StatelessWidget {
  const _CalculateButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<RiskRewardCubit>().state.submitting;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.calculate_rounded),
        label: Text(busy ? 'Calculating…' : 'Calculate'),
      ),
    );
  }
}

class _AutoLeverageCard extends StatelessWidget {
  const _AutoLeverageCard({
    required this.leverage,
    required this.stopDistancePercent,
  });

  final int? leverage;
  final double? stopDistancePercent;

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: TradeXColors.gold.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TradeXColors.goldSoft.withValues(alpha: .55),
            ),
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: TradeXColors.goldBright,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calculated Leverage',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                leverage == null
                    ? 'Enter a valid Entry and Stop Loss to calculate leverage.'
                    : '${stopDistancePercent!.toStringAsFixed(2)}% stop distance • safety buffer included',
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          leverage == null ? '--' : '${leverage}x',
          style: TextStyle(
            color: leverage == null
                ? TradeXColors.tertiaryText
                : TradeXColors.goldBright,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    dropdownColor: TradeXColors.surfaceRaised,
    decoration: _inputDecoration(
      'Payments per Year',
      Icons.calendar_month_rounded,
    ),
    items: const [1, 2, 4, 12]
        .map(
          (item) =>
              DropdownMenuItem(value: item, child: Text('$item payments')),
        )
        .toList(growable: false),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.text,
    this.icon = Icons.cloud_off_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: TradeXColors.goldSoft.withValues(alpha: .5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: TradeXColors.goldBright),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TradeXColors.error.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: TradeXColors.error.withValues(alpha: .7)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: TradeXColors.error),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: TradeXColors.primaryText),
          ),
        ),
      ],
    ),
  );
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? 18 : 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: TradeXColors.goldBright),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
        ],
      ),
    ),
  );
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: TradeXColors.goldBright,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.primaryText,
      fontSize: 18,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _EmptyProviderState extends StatelessWidget {
  const _EmptyProviderState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Column(
      children: [
        const _AssetImage('22_clock_calendar_tile.png', size: 74),
        const SizedBox(height: 10),
        const Text(
          'Verified provider unavailable',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _JsonDetailCard extends StatelessWidget {
  const _JsonDetailCard({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 10),
          for (final entry in data.entries)
            if (entry.value != null && entry.value.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _labelize(entry.key),
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _displayValue(entry.value),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );
}

class _SideBadge extends StatelessWidget {
  const _SideBadge(this.side);

  final String side;

  @override
  Widget build(BuildContext context) {
    final buy = side.toUpperCase() == 'BUY';
    final color = buy ? TradeXColors.success : TradeXColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        side.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: TradeXColors.warning,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SavedCalculationTile extends StatelessWidget {
  const _SavedCalculationTile({required this.item});

  final SavedCalculation item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _GoldCard(
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded, color: TradeXColors.goldBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.type.replaceAll('_', ' ')}${item.createdAt == null ? '' : '  •  ${_shortDate(item.createdAt!)}'}',
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: TradeXColors.secondaryText),
      prefixIcon: Icon(icon, color: TradeXColors.goldBright),
      filled: true,
      fillColor: TradeXColors.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TradeXColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: TradeXColors.goldBright,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );

Future<void> _open(BuildContext context, Widget screen) {
  final cubit = context.read<RiskRewardCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(value: cubit, child: screen),
    ),
  );
}

StockInstrument? _findStock(List<StockInstrument> stocks, String? symbol) {
  for (final stock in stocks) {
    if (stock.symbol == symbol) return stock;
  }
  return null;
}

double _metricWidth(double available) =>
    available >= 520 ? (available - 10) / 2 : available;

String _formatNumber(num? value) {
  if (value == null) return '—';
  final number = value.toDouble();
  if (number == number.roundToDouble()) return number.toStringAsFixed(0);
  return number
      .toStringAsFixed(number.abs() < 1 ? 6 : 2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _money(num? value) => value == null ? '—' : '\$${_formatNumber(value)}';

String _currency(num? value, String currency) =>
    value == null ? '—' : '$currency ${_formatNumber(value)}';

String _labelize(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _displayValue(Object? value) {
  if (value is Map || value is List) return value.toString();
  return value?.toString() ?? '—';
}

String _shortDate(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
