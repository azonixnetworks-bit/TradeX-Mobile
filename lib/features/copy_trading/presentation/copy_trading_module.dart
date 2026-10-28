import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/usecases/use_case.dart';
import '../domain/entities/copy_trading_entities.dart';
import '../domain/usecases/copy_trading_use_cases.dart';
import 'copy_trading_widgets.dart';

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
          CopyHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CopyPageHeading(
                  title: 'Official cTrader',
                  goldTitle: 'Copy',
                  subtitle: 'Manage verified copy trading accounts securely.',
                  icon: Icons.sync_alt_rounded,
                ),
                const SizedBox(height: 22),
                Text(
                  accounts.isEmpty
                      ? 'No Connected Account'
                      : '${active.length} Active ${active.length == 1 ? 'Account' : 'Accounts'}',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  accounts.isEmpty
                      ? 'Choose a TradeX IB broker to begin verification.'
                      : '${verified.length} verified · ${pending.length} awaiting review',
                  style: const TextStyle(color: copyMuted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                CopyStatusPill(
                  status: data.copyTradeReady ? 'ACTIVE' : data.nextStep,
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

class CopyTradingBrokerDirectoryScreen extends StatefulWidget {
  const CopyTradingBrokerDirectoryScreen({super.key, required this.useCases});
  final CopyTradingUseCases useCases;

  @override
  State<CopyTradingBrokerDirectoryScreen> createState() =>
      _CopyTradingBrokerDirectoryScreenState();
}

class _CopyTradingBrokerDirectoryScreenState
    extends State<CopyTradingBrokerDirectoryScreen> {
  late Future<List<CopyTradingBrokerMarket>> _future;
  String _market = 'FOREX';
  String? _workingMarket;
  final _intentMarkets = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _loadBrokers();
  }

  Future<List<CopyTradingBrokerMarket>> _loadBrokers() async {
    final brokers = await widget.useCases.getBrokers(const NoParams());
    final pending = await Future.wait(
      brokers.map((broker) async {
        final marketId = broker.brokerMarketUuid;
        if (marketId.isEmpty) return null;
        return await widget.useCases.getPendingIntent(marketId) == null
            ? null
            : marketId;
      }),
    );
    _intentMarkets
      ..clear()
      ..addAll(pending.whereType<String>());
    return brokers;
  }

  Future<void> _openBroker(CopyTradingBrokerMarket broker) async {
    final marketId = broker.brokerMarketUuid;
    if (marketId.isEmpty || _workingMarket != null) return;
    setState(() => _workingMarket = marketId);
    try {
      final intent = await widget.useCases.openBrokerAccount(broker);
      final target = intent.openAccountUrl;
      if (target.isEmpty ||
          !await launchUrl(
            Uri.parse(target),
            mode: LaunchMode.externalApplication,
          )) {
        throw StateError('TradeX IB partner link could not be opened.');
      }
      if (!mounted) return;
      setState(() => _intentMarkets.add(marketId));
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CopyTradingVerificationScreen(
            useCases: widget.useCases,
            broker: broker,
          ),
        ),
      );
    } catch (error) {
      _message(_error(error));
    } finally {
      if (mounted) setState(() => _workingMarket = null);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<CopyTradingBrokerMarket>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const CopyLoadingState();
      }
      if (snapshot.hasError) {
        return CopyErrorState(
          message: _error(snapshot.error),
          onRetry: () => setState(() => _future = _loadBrokers()),
        );
      }
      final brokers = snapshot.data ?? const [];
      final visible = brokers.where((item) => item.marketCategory == _market);
      return CopyTradingScrollPage(
        children: [
          const CopyHeroCard(
            child: CopyPageHeading(
              title: 'Choose Your',
              goldTitle: 'Broker',
              subtitle: 'Open a LIVE account through TradeX and connect cTrader only.',
            ),
          ),
          const SizedBox(height: 14),
          _MarketSelector(
            value: _market,
            onChanged: (value) => setState(() => _market = value),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            CopyEmptyState(
              icon: Icons.business_outlined,
              title: 'No configured broker',
              message:
                  'Laravel has not published an active $_market broker market yet.',
            )
          else
            for (final broker in visible) ...[
              _BrokerDirectoryCard(
                useCases: widget.useCases,
                broker: broker,
                busy: _workingMarket == broker.brokerMarketUuid,
                hasIntent: _intentMarkets.contains(broker.brokerMarketUuid),
                onOpen: () => _openBroker(broker),
                onContinue: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CopyTradingVerificationScreen(
                      useCases: widget.useCases,
                      broker: broker,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 8),
          const _HowItWorks(),
        ],
      );
    },
  );

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class CopyTradingVerificationScreen extends StatefulWidget {
  const CopyTradingVerificationScreen({
    super.key,
    required this.useCases,
    this.broker,
    this.account,
  });

  final CopyTradingUseCases useCases;
  final CopyTradingBrokerMarket? broker;
  final CopyTradingAccount? account;

  @override
  State<CopyTradingVerificationScreen> createState() =>
      _CopyTradingVerificationScreenState();
}

class _CopyTradingVerificationScreenState
    extends State<CopyTradingVerificationScreen> {
  final _key = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  CopyTradingAccount? _account;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  @override
  void dispose() {
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true || _working) return;
    setState(() => _working = true);
    try {
      final existing = _account;
      final result = existing != null
          ? await widget.useCases.resubmitBrokerAccount(
              ResubmitCopyTradingAccountParams(
                accountId: existing.uuid,
                accountNumber: _accountNumber.text.trim(),
              ),
            )
          : await widget.useCases.submitBrokerAccount(
              SubmitCopyTradingAccountParams(
                marketId: widget.broker!.brokerMarketUuid,
                accountNumber: _accountNumber.text.trim(),
              ),
            );
      if (!mounted) return;
      setState(() => _account = result);
      _message('Account submitted for TradeX IB verification.');
    } catch (error) {
      _message(_error(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final broker = account == null ? widget.broker! : account.broker;
    final brokerName = broker.brokerName;
    final market = account == null
        ? broker.marketCategory
        : account.marketCategory;
    final currency = account?.verifiedCurrency ?? broker.requiredCurrency;
    final status = account == null
        ? 'ACCOUNT DETAILS'
        : copyAccountStatus(account);
    final canSubmit = account == null || status == 'NEEDS_RESUBMISSION';

    return CopyTradingScrollPage(
      children: [
        const CopyHeroCard(
          child: CopyPageHeading(
            title: 'Account',
            goldTitle: 'Verification',
            subtitle: 'Connect your LIVE cTrader account through secure verification.',
          ),
        ),
        const SizedBox(height: 14),
        _VerificationSteps(status: status),
        const SizedBox(height: 12),
        CopySectionCard(
          child: Row(
            children: [
              CopyBrokerLogo(
                useCases: widget.useCases,
                name: brokerName,
                logoUrl: broker.logoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brokerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$market · cTrader only',
                      style: const TextStyle(color: copyMuted),
                    ),
                  ],
                ),
              ),
              CopyStatusPill(status: status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (canSubmit)
          CopySectionCard(
            highlight: true,
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CopySectionHeading(
                    title: 'Account Details',
                    subtitle: 'Never enter a password, OTP or API secret.',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _accountNumber,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 15,
                    decoration: const InputDecoration(
                      labelText: 'Broker account number',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Broker account number is required.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _ReadOnlyField(
                    icon: Icons.layers_outlined,
                    label: 'Account Type',
                    value: 'LIVE',
                  ),
                  const SizedBox(height: 10),
                  _ReadOnlyField(
                    icon: Icons.paid_outlined,
                    label: 'Required Currency',
                    value: currency,
                  ),
                  const SizedBox(height: 14),
                  CopyPrimaryButton(
                    label: account == null
                        ? 'Submit for Verification'
                        : 'Resubmit Corrected Account',
                    onPressed: _submit,
                    busy: _working,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
          )
        else
          CopyEmptyState(
            icon: status == 'ACTIVE'
                ? Icons.verified_rounded
                : Icons.hourglass_top_rounded,
            title: status.replaceAll('_', ' '),
            message: account.statusReason ?? 'TradeX is keeping verification and activation as separate security checks.',
          ),
        const SizedBox(height: 12),
        _VerificationTimeline(status: status),
      ],
    );
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class CopyTradingBotActivationScreen extends StatefulWidget {
  const CopyTradingBotActivationScreen({
    super.key,
    required this.useCases,
    required this.account,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;

  @override
  State<CopyTradingBotActivationScreen> createState() =>
      _CopyTradingBotActivationScreenState();
}

class _CopyTradingBotActivationScreenState
    extends State<CopyTradingBotActivationScreen> {
  late Future<CopyTradingActivation> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.useCases.getActivation(widget.account.uuid);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CopyTradingActivation>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const CopyLoadingState();
      }
      if (snapshot.hasError) {
        return CopyErrorState(
          message: _error(snapshot.error),
          onRetry: () => setState(
            () => _future = widget.useCases.getActivation(widget.account.uuid),
          ),
        );
      }
      final activation = snapshot.data!;
      final state = activation.state.isEmpty
          ? widget.account.activationState
          : activation.state;
      final ready = activation.copyTradeReady;
      return CopyTradingScrollPage(
        children: [
          CopyHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompactAccountHeader(
                  useCases: widget.useCases,
                  account: widget.account,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Icon(
                      ready ? Icons.check_circle_rounded : Icons.rule_rounded,
                      color: ready ? copyGreen : copyGold,
                      size: 34,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ready ? 'Verified & Ready' : state.replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CopySectionCard(
            highlight: true,
            child: Column(
              children: [
                const Row(
                  children: [
                    CopyIconBadge(icon: Icons.smart_toy_outlined, size: 58),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TradeX cTrader Copy Bot',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Backend bot-control endpoint unavailable',
                            style: TextStyle(color: copyMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                CopyPrimaryButton(
                  label: 'Bot Activation Unavailable',
                  onPressed: null,
                  icon: Icons.block_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CopySectionHeading(title: 'Setup Steps'),
          const SizedBox(height: 9),
          const CopySectionCard(
            child: Column(
              children: [
                _SetupStep(
                  number: '1',
                  title: 'Verify account',
                  subtitle: 'TradeX confirms IB attribution and LIVE status.',
                ),
                _SetupStep(
                  number: '2',
                  title: 'Pass eligibility gates',
                  subtitle: 'Premium, currency and balance rules are checked.',
                ),
                _SetupStep(
                  number: '3',
                  title: 'Bot service integration',
                  subtitle:
                      'Coming after a secure Laravel bot API is available.',
                ),
                _SetupStep(
                  number: '4',
                  title: 'Start cTrader copy trading',
                  subtitle:
                      'Unavailable until backend connection is confirmed.',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CopyEmptyState(
            icon: Icons.security_rounded,
            title: 'cTrader only',
            message: 'MT4, MT5 and any unverified execution engine are intentionally excluded.',
          ),
        ],
      );
    },
  );
}

class CopyTradingLiveDashboardScreen extends StatelessWidget {
  const CopyTradingLiveDashboardScreen({
    super.key,
    required this.useCases,
    required this.account,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;

  @override
  Widget build(BuildContext context) => CopyTradingScrollPage(
    children: [
      CopySectionCard(
        highlight: true,
        child: _CompactAccountHeader(useCases: useCases, account: account),
      ),
      const SizedBox(height: 14),
      const CopySectionHeading(
        title: 'Account Performance',
        subtitle: 'Live data from your connected cTrader account.',
      ),
      const SizedBox(height: 10),
      const CopyEmptyState(
        icon: Icons.query_stats_rounded,
        title: 'Live telemetry unavailable',
        message: 'The current Laravel API does not provide balance, equity, P&L, margin or chart data. No values are being simulated.',
      ),
      const SizedBox(height: 14),
      const CopySectionHeading(title: 'Open Positions'),
      const SizedBox(height: 10),
      const CopyEmptyState(
        icon: Icons.candlestick_chart_outlined,
        title: 'No live positions endpoint',
        message: 'Open cTrader positions will appear here only after an authenticated telemetry endpoint is implemented.',
      ),
      const SizedBox(height: 14),
      CopySectionCard(
        child: Row(
          children: [
            const CopyIconBadge(icon: Icons.smart_toy_outlined),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Copy Trading Bot Health',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Bot telemetry endpoint unavailable',
                    style: TextStyle(color: copyMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const CopyStatusPill(status: 'UNAVAILABLE'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      CopyPrimaryButton(
        label: 'History & Settings',
        icon: Icons.history_rounded,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CopyTradingHistorySettingsScreen(
              useCases: useCases,
              account: account,
            ),
          ),
        ),
      ),
    ],
  );
}

class CopyTradingHistorySettingsScreen extends StatefulWidget {
  const CopyTradingHistorySettingsScreen({
    super.key,
    required this.useCases,
    required this.account,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;

  @override
  State<CopyTradingHistorySettingsScreen> createState() =>
      _CopyTradingHistorySettingsScreenState();
}

class _CopyTradingHistorySettingsScreenState
    extends State<CopyTradingHistorySettingsScreen> {
  bool _history = true;

  @override
  Widget build(BuildContext context) => CopyTradingScrollPage(
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0D0B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: copyGold.withValues(alpha: .7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                selected: _history,
                icon: Icons.history_rounded,
                label: 'History',
                onTap: () => setState(() => _history = true),
              ),
            ),
            Expanded(
              child: _TabButton(
                selected: !_history,
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => setState(() => _history = false),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      CopyHeroCard(
        child: _CompactAccountHeader(
          useCases: widget.useCases,
          account: widget.account,
        ),
      ),
      const SizedBox(height: 14),
      if (_history) ...[
        const CopySectionHeading(title: 'Recent Closed Trades'),
        const SizedBox(height: 10),
        const CopyEmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: 'Trade history unavailable',
          message: 'The current backend has billing history but no cTrader closed-trades endpoint. No trade rows are fabricated.',
        ),
        const SizedBox(height: 12),
        CopyPrimaryButton(
          label: 'Statement Unavailable',
          icon: Icons.download_for_offline_outlined,
          onPressed: null,
        ),
      ] else ...[
        const CopySectionHeading(title: 'Copy Settings'),
        const SizedBox(height: 10),
        const CopySectionCard(
          child: Column(
            children: [
              _UnavailableSetting(
                icon: Icons.notifications_none_rounded,
                title: 'Trade Notifications',
              ),
              Divider(),
              _UnavailableSetting(
                icon: Icons.sync_rounded,
                title: 'Auto Sync Trades',
              ),
              Divider(),
              _UnavailableSetting(
                icon: Icons.shield_outlined,
                title: 'Risk Alert Level',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CopyEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Settings are read-only',
          message: 'These controls will activate only when Laravel exposes authorized cTrader settings and stop-copying endpoints.',
        ),
      ],
    ],
  );
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: CopySectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CopyIconBadge(icon: icon),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: copyMuted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.useCases,
    required this.account,
    required this.onTap,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final broker = copyAccountBroker(account);
    final name = broker.brokerName;
    return CopySectionCard(
      onTap: onTap,
      child: Row(
        children: [
          CopyBrokerLogo(
            useCases: useCases,
            name: name,
            logoUrl: broker.logoUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${account.marketCategory} · ${account.accountNumberMasked}',
                  style: const TextStyle(color: copyMuted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                const Text(
                  'cTrader Copy',
                  style: TextStyle(color: copyGold, fontSize: 11),
                ),
              ],
            ),
          ),
          CopyStatusPill(status: copyAccountStatus(account)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CopySectionCard(
    onTap: onTap,
    child: Row(
      children: [
        CopyIconBadge(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: copyMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: onTap == null ? Colors.white24 : copyGold,
        ),
      ],
    ),
  );
}

class _MarketSelector extends StatelessWidget {
  const _MarketSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return Row(
        children: ['FOREX', 'CRYPTO', 'DERIV']
            .map((market) {
              final selected = value == market;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: market == 'DERIV' ? 0 : 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => onChanged(market),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [Color(0xFF6A4A00), Color(0xFF1B1508)],
                              )
                            : null,
                        color: selected ? null : const Color(0xFF0B0E0D),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selected
                              ? copyGold
                              : copyGold.withValues(alpha: .4),
                        ),
                      ),
                      child: Column(
                        children: [
                          CopyMarketIcon(market: market, size: 36),
                          const SizedBox(height: 5),
                          Text(
                            market[0] + market.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected ? copyGold : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      );
    },
  );
}

class _BrokerDirectoryCard extends StatelessWidget {
  const _BrokerDirectoryCard({
    required this.useCases,
    required this.broker,
    required this.busy,
    required this.hasIntent,
    required this.onOpen,
    required this.onContinue,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingBrokerMarket broker;
  final bool busy;
  final bool hasIntent;
  final VoidCallback onOpen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final name = broker.brokerName;
    return CopySectionCard(
      child: Column(
        children: [
          Row(
            children: [
              CopyBrokerLogo(
                useCases: useCases,
                name: name,
                logoUrl: broker.logoUrl,
                size: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${broker.marketCategory} · ${broker.requiredCurrency}',
                      style: const TextStyle(color: copyMuted),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'TradeX configured · LIVE account required',
                      style: TextStyle(color: copyGold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          CopyPrimaryButton(
            label: hasIntent ? 'Continue Account Setup' : 'Open Account',
            onPressed: hasIntent ? onContinue : onOpen,
            busy: busy,
            icon: hasIntent
                ? Icons.arrow_forward_rounded
                : Icons.open_in_new_rounded,
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) => const CopySectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CopySectionHeading(title: 'How It Works'),
        SizedBox(height: 14),
        _SetupStep(
          number: '1',
          title: 'Open Account',
          subtitle: 'Use the returned TradeX IB referral URL.',
        ),
        _SetupStep(
          number: '2',
          title: 'Connect Account',
          subtitle: 'Submit only the LIVE broker account number.',
        ),
        _SetupStep(
          number: '3',
          title: 'Eligibility Review',
          subtitle: 'Admin verifies IB ownership before activation.',
          last: true,
        ),
      ],
    ),
  );
}

class _VerificationSteps extends StatelessWidget {
  const _VerificationSteps({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final completed = switch (status) {
      'ACTIVE' => 4,
      'VERIFIED' => 3,
      'PENDING' || 'ESCALATED' => 2,
      _ => 1,
    };
    return CopySectionCard(
      child: Row(
        children: List.generate(4, (index) {
          final active = index < completed;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? copyGold.withValues(alpha: .16)
                        : Colors.white.withValues(alpha: .04),
                    border: Border.all(
                      color: active ? copyGold : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? copyGold : Colors.white38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  const ['Details', 'Verify', 'Review', 'Done'][index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? copyGold : copyMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => CopySectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CopySectionHeading(
          title: 'Verification Timeline',
          subtitle: 'Server-confirmed account lifecycle.',
        ),
        const SizedBox(height: 14),
        _TimelineRow(
          title: 'Submission Received',
          state: status == 'ACCOUNT DETAILS' ? 'Not submitted' : 'Complete',
          active: status != 'ACCOUNT DETAILS',
        ),
        _TimelineRow(
          title: 'TradeX IB Review',
          state: status,
          active: const {
            'PENDING',
            'ESCALATED',
            'VERIFIED',
            'ACTIVE',
          }.contains(status),
        ),
        _TimelineRow(
          title: 'Eligibility Complete',
          state: status == 'ACTIVE' ? 'Complete' : 'Pending',
          active: status == 'ACTIVE',
          last: true,
        ),
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.state,
    required this.active,
    this.last = false,
  });
  final String title;
  final String state;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: active ? copyGold : Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
          if (!last) Container(width: 2, height: 36, color: Colors.white24),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      Text(
        state.replaceAll('_', ' '),
        style: TextStyle(color: active ? copyGold : copyMuted, fontSize: 11),
      ),
    ],
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Row(
      children: [
        Icon(icon, color: copyGold),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: copyMuted, fontSize: 11),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CompactAccountHeader extends StatelessWidget {
  const _CompactAccountHeader({required this.useCases, required this.account});
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;

  @override
  Widget build(BuildContext context) {
    final broker = copyAccountBroker(account);
    final name = broker.brokerName;
    return Row(
      children: [
        CopyBrokerLogo(
          useCases: useCases,
          name: name,
          logoUrl: broker.logoUrl,
          size: 60,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${account.marketCategory} · ${account.accountNumberMasked}',
                style: const TextStyle(color: copyMuted),
              ),
              const Text(
                'cTrader Copy',
                style: TextStyle(color: copyGold, fontSize: 11),
              ),
            ],
          ),
        ),
        CopyStatusPill(status: copyAccountStatus(account)),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.subtitle,
    this.last = false,
  });
  final String number;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: copyGold, width: 2),
              color: copyGold.withValues(alpha: .1),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: copyGold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!last) Container(width: 2, height: 42, color: copyGold),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: copyMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(26),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFFFFDE67), Color(0xFFFFB913)],
              )
            : null,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.black : copyMuted),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : copyMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _UnavailableSetting extends StatelessWidget {
  const _UnavailableSetting({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: copyGold),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: const Text(
      'Backend endpoint unavailable',
      style: TextStyle(color: copyMuted, fontSize: 11),
    ),
    trailing: Switch(value: false, onChanged: null),
  );
}

String _error(Object? error) {
  if (error is ApiException) return error.message;
  if (error is StateError) return error.message;
  return 'Copy Trading could not be loaded right now.';
}
