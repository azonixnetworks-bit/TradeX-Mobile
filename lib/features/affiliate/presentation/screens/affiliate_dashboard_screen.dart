part of '../affiliate_module.dart';

class AffiliateDashboardScreen extends StatelessWidget {
  const AffiliateDashboardScreen({
    super.key,
    required this.repository,
    required this.referralQrCache,
    required this.onUpgrade,
    required this.onConfigurePayoutMethod,
    this.onNotifications,
  });

  final AffiliateRepository repository;
  final ReferralQrCache referralQrCache;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigurePayoutMethod;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AffiliateLoadCubit(repository.overview)..load(),
      child: _DashboardBody(
        repository: repository,
        referralQrCache: referralQrCache,
        onUpgrade: onUpgrade,
        onConfigurePayoutMethod: onConfigurePayoutMethod,
        onNotifications: onNotifications,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.repository,
    required this.referralQrCache,
    required this.onUpgrade,
    required this.onConfigurePayoutMethod,
    this.onNotifications,
  });

  final AffiliateRepository repository;
  final ReferralQrCache referralQrCache;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigurePayoutMethod;
  final VoidCallback? onNotifications;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TradeXColors.surfaceRaised,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuTile(
                icon: Icons.people_alt_outlined,
                label: 'My Referrals',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliateReferralsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.bar_chart_rounded,
                label: 'Earnings & Sales',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliateEarningsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                      onConfigurePayoutMethod: onConfigurePayoutMethod,
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.workspace_premium_outlined,
                label: 'Levels & Rewards',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliateLevelsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Payouts & Withdrawals',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliatePayoutsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                      onConfigureMethod: onConfigurePayoutMethod,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
      builder: (context, state) => AffiliateScaffold(
        showBack: false,
        dashboardHeader: true,
        title: 'Affiliate Dashboard',
        subtitle: 'Invite traders. Grow together. Earn rewards.',
        onMenu: () => _openMenu(context),
        onNotifications: onNotifications,
        onRefresh: context.read<AffiliateLoadCubit>().load,
        child: AffiliateStateBody(
          state: state,
          onRetry: context.read<AffiliateLoadCubit>().load,
          onUpgrade: onUpgrade,
          builder: (data) => _DashboardContent(
            data: data,
            repository: repository,
            referralQrCache: referralQrCache,
            openReferrals: () => _open(
              context,
              AffiliateReferralsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
              ),
            ),
            openEarnings: () => _open(
              context,
              AffiliateEarningsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
                onConfigurePayoutMethod: onConfigurePayoutMethod,
              ),
            ),
            openLevels: () => _open(
              context,
              AffiliateLevelsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
              ),
            ),
            openPayouts: () => _open(
              context,
              AffiliatePayoutsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
                onConfigureMethod: onConfigurePayoutMethod,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.data,
    required this.repository,
    required this.referralQrCache,
    required this.openReferrals,
    required this.openEarnings,
    required this.openLevels,
    required this.openPayouts,
  });

  final JsonMap data;
  final AffiliateRepository repository;
  final ReferralQrCache referralQrCache;
  final VoidCallback openReferrals;
  final VoidCallback openEarnings;
  final VoidCallback openLevels;
  final VoidCallback openPayouts;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late Future<JsonMap> _payoutSummary;

  @override
  void initState() {
    super.initState();
    _payoutSummary = widget.repository.payoutSummary();
  }

  @override
  void didUpdateWidget(covariant _DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _payoutSummary = widget.repository.payoutSummary();
    }
  }

  Future<void> _shareExternal(BuildContext context, String channel) async {
    try {
      final result = await widget.repository.shareAction(channel);
      final url = Uri.tryParse(
        AffiliateRepository.text(result['external_share_url'], ''),
      );
      if (url == null ||
          !await AppPlatformRegistry.current.launchExternal(url.toString())) {
        throw const AffiliateException(
          message: 'The share app could not be opened.',
        );
      }
    } catch (error) {
      if (context.mounted) _snack(context, _message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final affiliate = AffiliateRepository.mapOf(widget.data['affiliate']);
    final referral = AffiliateRepository.mapOf(widget.data['referral']);
    final financials = AffiliateRepository.mapOf(widget.data['financials']);
    final stage = AffiliateRepository.mapOf(widget.data['current_stage']);
    final commission = AffiliateRepository.mapOf(widget.data['commission']);
    final url = AffiliateRepository.text(referral['url'], '');
    final code = AffiliateRepository.text(referral['code'], '');
    final rate = AffiliateRepository.text(
      commission['next_sale_rate_percent'],
      '0.00',
    );
    final direct = AffiliateRepository.integer(
      referral['direct_referrals_count'],
    );
    final sales = AffiliateRepository.integer(
      widget.data['qualified_sales_count'],
    );
    final lifetimeEarnings = financials['lifetime_commission_earned'];
    final averageEarnings =
        AffiliateRepository.mapOf(
          financials['average_commission_per_qualified_sale'],
        ).isNotEmpty
        ? AffiliateRepository.moneyText(
            financials['average_commission_per_qualified_sale'],
          )
        : _averageEarningsPerSale(lifetimeEarnings, sales);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<JsonMap>(
          future: _payoutSummary,
          builder: (context, snapshot) {
            final summary = AffiliateRepository.mapOf(
              snapshot.data?['summary'],
            );
            return _DashboardBalanceCard(
              balance: snapshot.connectionState == ConnectionState.waiting
                  ? null
                  : AffiliateRepository.moneyText(summary['available']),
              onWithdraw: widget.openPayouts,
            );
          },
        ),
        const SizedBox(height: 16),
        AffiliateHero(
          commissionRate: rate,
          onInvite: () => _nativeShare(context, url),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardMetricCard(
                  width: width,
                  label: 'Total Earnings',
                  value: AffiliateRepository.moneyText(
                    financials['lifetime_commission_earned'],
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: widget.openEarnings,
                ),
                _DashboardMetricCard(
                  width: width,
                  label: 'Qualified Sales',
                  value: '$sales',
                  icon: Icons.shopping_bag_rounded,
                  onTap: widget.openEarnings,
                ),
                _DashboardMetricCard(
                  width: width,
                  label: 'Total Referrals',
                  value: '$direct',
                  icon: Icons.groups_rounded,
                  onTap: widget.openReferrals,
                ),
                _DashboardMetricCard(
                  width: width,
                  label: 'Current Level',
                  value: AffiliateRepository.text(stage['name']),
                  subtitle: '$rate% commission',
                  icon: Icons.workspace_premium_rounded,
                  onTap: widget.openLevels,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ReferralLinkPanel(
          code: code,
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) _snack(context, 'Referral code copied.');
          },
          onWhatsApp: () => _shareExternal(context, 'WHATSAPP'),
          onTelegram: () => _shareExternal(context, 'TELEGRAM'),
          onShare: () => _shareAffiliateIncomeCard(
            context,
            clientName: AffiliateRepository.text(
              affiliate['name'],
              'TradeX Affiliate',
            ),
            referralUrl: url,
            referralCode: code,
            earnings: AffiliateRepository.moneyText(lifetimeEarnings),
            averageEarningsPerSale: averageEarnings,
            totalReferrals: direct,
            qualifiedSales: sales,
            commissionRate: rate,
            currentLevel: AffiliateRepository.text(stage['name'], 'Affiliate'),
          ),
          onQr: () => _showQr(
            context,
            url,
            cacheKey: code,
            cache: widget.referralQrCache,
          ),
        ),
        const SizedBox(height: 16),
        _CommissionRewardBanner(
          commissionRate: rate,
          onTap: widget.openPayouts,
        ),
      ],
    );
  }
}

class _DashboardBalanceCard extends StatelessWidget {
  const _DashboardBalanceCard({
    required this.balance,
    required this.onWithdraw,
  });

  final String? balance;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) => SectionCard(
    borderColor: context.palette.gold,
    child: Row(
      children: [
        const _GoldIcon(Icons.account_balance_wallet_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              if (balance == null)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  balance!,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
        GoldActionButton(
          label: 'Withdraw',
          onPressed: onWithdraw,
          compact: true,
        ),
      ],
    ),
  );
}
