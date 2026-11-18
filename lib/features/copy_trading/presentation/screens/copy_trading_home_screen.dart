part of '../copy_trading_module.dart';

class CopyTradingHomeScreen extends StatefulWidget {
  const CopyTradingHomeScreen({super.key, required this.useCases});

  final CopyTradingUseCases useCases;

  @override
  State<CopyTradingHomeScreen> createState() => _CopyTradingHomeScreenState();
}

class _CopyTradingHomeScreenState extends State<CopyTradingHomeScreen> {
  late Future<CopyTradingDashboard> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.useCases.getDashboard(const NoParams());

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CopyTradingDashboard>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const CopyLoadingState();
      }
      if (snapshot.hasError) {
        return CopyErrorState(
          message: _error(snapshot.error),
          onRetry: () => setState(_reload),
        );
      }
      final data = snapshot.data!;
      final accounts = data.accounts;
      final active = accounts.where((account) => account.isActive);
      final pending = accounts.where((account) => account.needsReview);
      final verified = accounts.where((account) => account.isVerified);
      return CopyTradingScrollPage(
        onRefresh: _refresh,
        children: [
          const CopyPageHeading(
            title: 'Official cTrader',
            goldTitle: 'Copy',
            subtitle: 'Manage verified copy trading accounts securely.',
            icon: Icons.sync_alt_rounded,
          ),
          const SizedBox(height: 18),
          CopySectionCard(
            highlight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CopyIconBadge(
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accounts.isEmpty
                                ? 'No Connected Account'
                                : '${active.length} Active ${active.length == 1 ? 'Account' : 'Accounts'}',
                            style: TextStyle(
                              color: context.palette.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            accounts.isEmpty
                                ? 'Choose a TradeX IB broker to begin verification.'
                                : '${verified.length} verified · ${pending.length} awaiting review',
                            style: TextStyle(
                              color: context.palette.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CopyStatusPill(
                    status: data.copyTradeReady ? 'ACTIVE' : data.nextStep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 360
                  ? constraints.maxWidth
                  : constraints.maxWidth < 520
                  ? (constraints.maxWidth - 10) / 2
                  : (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HomeMetric(
                    width: width,
                    icon: Icons.people_alt_outlined,
                    value: '${active.length}',
                    label: 'Connected Accounts',
                    onTap: active.isEmpty
                        ? null
                        : () => _open(
                            CopyTradingLiveDashboardScreen(
                              useCases: widget.useCases,
                              account: active.first,
                            ),
                          ),
                  ),
                  _HomeMetric(
                    width: width,
                    icon: Icons.fact_check_outlined,
                    value: '${pending.length}',
                    label: 'Pending Verification',
                    onTap: pending.isEmpty
                        ? null
                        : () => _open(
                            CopyTradingVerificationScreen(
                              useCases: widget.useCases,
                              account: pending.first,
                            ),
                          ),
                  ),
                  _HomeMetric(
                    width: width,
                    icon: Icons.smart_toy_outlined,
                    value: 'Unavailable',
                    label: 'Bot Status',
                    onTap: verified.isEmpty
                        ? null
                        : () => _open(
                            CopyTradingBotActivationScreen(
                              useCases: widget.useCases,
                              account: verified.first,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          CopySectionHeading(
            title: 'My Accounts',
            action: accounts.isEmpty ? null : 'Manage all',
            onAction: accounts.isEmpty
                ? null
                : () => _open(
                    CopyTradingHistorySettingsScreen(
                      useCases: widget.useCases,
                      account: accounts.first,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          if (accounts.isEmpty)
            CopyEmptyState(
              title: 'No cTrader accounts yet',
              message: 'Open an eligible LIVE account through a TradeX IB link, then submit its account number.',
              action: 'Choose broker',
              onAction: () => _open(
                CopyTradingBrokerDirectoryScreen(useCases: widget.useCases),
              ),
            )
          else
            for (final account in accounts) ...[
              _AccountCard(
                useCases: widget.useCases,
                account: account,
                onTap: () => _open(_destination(account)),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          const CopySectionHeading(title: 'Quick Actions'),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.add_rounded,
            title: 'Open New Account',
            subtitle: 'Use an approved TradeX IB partner link.',
            onTap: () => _open(
              CopyTradingBrokerDirectoryScreen(useCases: widget.useCases),
            ),
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.description_outlined,
            title: 'Submit Account',
            subtitle: 'Choose the broker first to create a secure intent.',
            onTap: () => _open(
              CopyTradingBrokerDirectoryScreen(useCases: widget.useCases),
            ),
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.monitor_heart_outlined,
            title: 'Live Dashboard',
            subtitle: active.isEmpty
                ? 'No active account is available.'
                : 'Open your verified cTrader account.',
            onTap: active.isEmpty
                ? null
                : () => _open(
                    CopyTradingLiveDashboardScreen(
                      useCases: widget.useCases,
                      account: active.first,
                    ),
                  ),
          ),
        ],
      );
    },
  );

  Widget _destination(CopyTradingAccount account) {
    return switch (copyAccountStatus(account)) {
      'ACTIVE' => CopyTradingLiveDashboardScreen(
        useCases: widget.useCases,
        account: account,
      ),
      'VERIFIED' => CopyTradingBotActivationScreen(
        useCases: widget.useCases,
        account: account,
      ),
      _ => CopyTradingVerificationScreen(
        useCases: widget.useCases,
        account: account,
      ),
    };
  }
}
