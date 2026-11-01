part of '../investment_module.dart';

class InvestmentHomeScreen extends StatefulWidget {
  const InvestmentHomeScreen({
    super.key,
    required this.repository,
    this.preferencesRepository,
  });

  final InvestmentRepository repository;
  final InvestmentPreferencesRepository? preferencesRepository;

  @override
  State<InvestmentHomeScreen> createState() => _InvestmentHomeScreenState();
}

class _InvestmentHomeScreenState extends State<InvestmentHomeScreen>
    with WidgetsBindingObserver {
  late final InvestmentsCubit _cubit;
  bool _hideValues = false;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = InvestmentsCubit(widget.repository)..load();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final hideValues =
        await widget.preferencesRepository?.hideValues() ?? false;
    if (!mounted) return;
    setState(() => _hideValues = hideValues);
  }

  Future<void> _toggleHidden() async {
    final value = !_hideValues;
    setState(() => _hideValues = value);
    await widget.preferencesRepository?.setHideValues(value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < const Duration(minutes: 2)) {
      return;
    }
    _lastRefresh = now;
    _cubit.load(refresh: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: _InvestmentScaffold(
      title: 'Investments',
      child: BlocBuilder<InvestmentsCubit, InvestmentsState>(
        builder: (context, state) {
          if (state.status == InvestmentsStatus.loading &&
              state.dashboard == null) {
            return const _InvestmentLoading();
          }
          final dashboard = state.dashboard;
          final portfolio = dashboard?.portfolio;
          final active = dashboard?.investments
              .where((item) => item.status == InvestmentStatus.active)
              .toList(growable: false);
          final hasBlockingError =
              state.status == InvestmentsStatus.error && dashboard == null;
          return RefreshIndicator(
            onRefresh: () => _cubit.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (dashboard?.isStale == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InvestmentRiskNotice(
                      'Offline data shown as of ${_date(dashboard?.cachedAt)}.',
                    ),
                  ),
                if (hasBlockingError) ...[
                  _InvestmentUnavailable(
                    message:
                        state.message ??
                        'Unable to load investments. Please try again.',
                    onRetry: () => _cubit.load(refresh: true),
                  ),
                  const SizedBox(height: 18),
                ],
                _InvestmentCard(
                  emphasized: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'PORTFOLIO OVERVIEW',
                              style: TextStyle(
                                color: TradeXColors.goldBright,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .7,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _toggleHidden,
                            icon: Icon(
                              _hideValues
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _hideValues ? 'Show values' : 'Hide values',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _money(
                          portfolio?.portfolioValue,
                          portfolio?.currency,
                          hidden: _hideValues,
                        ),
                        style: const TextStyle(
                          color: _investmentText,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Current portfolio value',
                        style: TextStyle(color: _investmentMuted),
                      ),
                      const Divider(height: 28, color: _investmentCardBorder),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeValue(
                              label: 'Total invested',
                              value: _money(
                                portfolio?.totalInvested,
                                portfolio?.currency,
                                hidden: _hideValues,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _HomeValue(
                              label: 'Verified profit',
                              value: _money(
                                portfolio?.verifiedProfit,
                                portfolio?.currency,
                                hidden: _hideValues,
                              ),
                              positive: portfolio?.verifiedProfit != null,
                            ),
                          ),
                        ],
                      ),
                      if (portfolio?.valuedAt != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Valuation as of ${_date(portfolio?.valuedAt)}',
                          style: const TextStyle(
                            color: _investmentMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InvestmentMetric(
                        label: 'Active investments',
                        value: portfolio?.activeCount?.toString() ?? '—',
                        icon: Icons.diamond_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InvestmentMetric(
                        label: 'Next review',
                        value: _date(portfolio?.nextReviewAt),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _InvestmentSectionTitle('Explore Investments'),
                const SizedBox(height: 12),
                _InvestmentNavTile(
                  title: 'Available Products',
                  icon: Icons.diamond_outlined,
                  onTap: () => _open(
                    InvestmentProductsScreen(repository: widget.repository),
                  ),
                ),
                const SizedBox(height: 10),
                _InvestmentNavTile(
                  title: 'My Investments',
                  icon: Icons.receipt_long_rounded,
                  onTap: () =>
                      _open(MyInvestmentsScreen(repository: widget.repository)),
                ),
                const SizedBox(height: 10),
                _InvestmentNavTile(
                  title: 'Profit Performance',
                  icon: Icons.query_stats_rounded,
                  onTap: () => _open(
                    ProfitPerformanceScreen(repository: widget.repository),
                  ),
                ),
                const SizedBox(height: 10),
                _InvestmentNavTile(
                  title: 'Transactions',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () => _open(
                    InvestmentTransactionsScreen(repository: widget.repository),
                  ),
                ),
                const SizedBox(height: 10),
                _InvestmentNavTile(
                  title: 'Agreements & Risk',
                  icon: Icons.gavel_rounded,
                  onTap: () => _open(
                    InvestmentAgreementsRiskScreen(
                      repository: widget.repository,
                    ),
                  ),
                ),
                if (state.status == InvestmentsStatus.error &&
                    dashboard != null) ...[
                  const SizedBox(height: 18),
                  _InvestmentUnavailable(
                    message:
                        state.message ??
                        'Unable to load investments. Please try again.',
                    onRetry: () => _cubit.load(refresh: true),
                  ),
                ] else if (active?.isNotEmpty == true) ...[
                  const SizedBox(height: 22),
                  const _InvestmentSectionTitle('Active Investment'),
                  const SizedBox(height: 12),
                  _InvestmentPreviewCard(
                    investment: active!.first,
                    onTap: () => _open(
                      InvestmentDetailsScreen(
                        repository: widget.repository,
                        investmentId: active.first.id,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  const _InvestmentEmpty(),
                ],
                const SizedBox(height: 18),
                const _InvestmentRiskNotice(
                  'Important Investment Risk\nCapital may be partially or completely lost. Returns are not guaranteed.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Read-only dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _investmentMuted, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _HomeValue extends StatelessWidget {
  const _HomeValue({
    required this.label,
    required this.value,
    this.positive = false,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: _investmentMuted)),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          color: positive ? _investmentGreen : _investmentText,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _InvestmentPreviewCard extends StatelessWidget {
  const _InvestmentPreviewCard({required this.investment, required this.onTap});

  final CustomerInvestment investment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _InvestmentCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.currency_bitcoin_rounded,
              color: TradeXColors.goldBright,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment.productName,
                    style: const TextStyle(
                      color: _investmentText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    investment.code,
                    style: const TextStyle(color: _investmentMuted),
                  ),
                ],
              ),
            ),
            _InvestmentStatusBadge(_investmentStatusLabel(investment.status)),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${_money(investment.amount, investment.currency)} · ${((investment.progress ?? 0) * 100).round()}% completed',
          style: const TextStyle(
            color: _investmentText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: investment.progress?.clamp(0, 1),
          minHeight: 7,
          borderRadius: BorderRadius.circular(10),
          color: TradeXColors.goldBright,
          backgroundColor: const Color(0xFF3B3D42),
        ),
      ],
    ),
  );
}
