part of '../risk_reward_module.dart';

class RiskRewardHomeScreen extends StatefulWidget {
  const RiskRewardHomeScreen({super.key, required this.repository});

  final RiskRewardRepository repository;

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
        const _Eyebrow('RISK MANAGEMENT'),
        const SizedBox(height: 8),
        const _GradientTitle(first: 'Risk Reward', second: 'Dashboard'),
        const SizedBox(height: 12),
        Text(
          'Plan position size, margin and reward using verified market specifications.',
          style: TextStyle(
            color: context.palette.secondaryText,
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
        const _SectionTitle('Quick Tools'),
        const SizedBox(height: 10),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trade Smarter —',
                style: TextStyle(
                  color: context.palette.goldText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Manage Your Risk',
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use verified specifications and server-side calculations to plan with confidence.',
                style: TextStyle(
                  color: context.palette.secondaryText,
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
                  style: TextStyle(
                    color: context.palette.goldText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.palette.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.palette.goldText),
        ],
      ),
    ),
  );
}
