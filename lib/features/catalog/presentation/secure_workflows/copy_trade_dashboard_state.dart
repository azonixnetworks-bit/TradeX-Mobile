part of '../secure_workflow_screens.dart';

class _CopyTradeDashboardScreenState extends State<CopyTradeDashboardScreen>
    with WidgetsBindingObserver {
  static const _markets = ['ALL', 'FOREX', 'CRYPTO', 'DERIV'];

  late Future<Map<String, dynamic>> _request;
  final Map<String, Map<String, dynamic>> _pendingIntents = {};
  String _market = 'ALL';
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    setState(() {
      _request = widget.apiClient.getJson('/api/v1/copy-trade/bootstrap');
    });
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Copy Trading',
    child: BlocFutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: _Busy());
        }
        if (snapshot.hasError) {
          return _CopyTradeError(error: snapshot.error, onRetry: _reload);
        }

        final data = _payload(snapshot.data);
        final accounts = _list(data['broker_accounts']);
        final brokers = _list(data['brokers']);
        final premium = _mapValue(data['education_premium']);
        final ready = data['copy_trade_ready'] == true;
        final nextStep = data['next_step']?.toString() ?? 'CONNECT_BROKER';
        final filteredBrokers = brokers
            .where((broker) {
              return _market == 'ALL' ||
                  broker['market_category']?.toString().toUpperCase() ==
                      _market;
            })
            .toList(growable: false);
        final filteredAccounts = accounts
            .where((account) {
              return _market == 'ALL' ||
                  account['market_category']?.toString().toUpperCase() ==
                      _market;
            })
            .toList(growable: false);

        return RefreshIndicator(
          color: TradeXColors.gold,
          onRefresh: () async {
            _reload();
            await _request;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _CopyTradeHero(
                ready: ready,
                nextStep: nextStep,
                premiumActive: premium['active'] == true,
              ),
              const SizedBox(height: 16),
              _CopyTradeMarketPicker(
                values: _markets,
                selected: _market,
                onSelected: (value) => setState(() => _market = value),
              ),
              const SizedBox(height: 20),
              _CopyTradeHeading(
                title: 'Your broker accounts',
                subtitle: 'Verification and eligibility are shown separately.',
                trailing: '${filteredAccounts.length}',
              ),
              const SizedBox(height: 10),
              if (filteredAccounts.isEmpty)
                const _CopyTradeEmpty(
                  icon: Icons.account_balance_wallet_outlined,
                  message: 'No broker account submitted for this market yet.',
                )
              else
                for (final account in filteredAccounts) ...[
                  _CopyTradeAccountCard(
                    account: account,
                    working: _working,
                    onResubmit: () => _showResubmitForm(account),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 18),
              const _CopyTradeHeading(
                title: 'Open or connect an account',
                subtitle: 'Use the TradeX partner link, then submit only your account number.',
              ),
              const SizedBox(height: 10),
              if (premium['active'] != true)
                const _SecurityNotice(
                  'Education Premium is required before broker onboarding. Your broker password is never requested.',
                )
              else if (filteredBrokers.isEmpty)
                const _CopyTradeEmpty(
                  icon: Icons.business_outlined,
                  message: 'No active broker is configured for this market.',
                )
              else
                for (final broker in filteredBrokers) ...[
                  _CopyTradeBrokerCard(
                    broker: broker,
                    hasIntent: _pendingIntents.containsKey(
                      broker['broker_market_uuid']?.toString(),
                    ),
                    working: _working,
                    onOpen: () => _openBroker(broker),
                    onSubmit: () => _showAccountForm(broker),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 10),
              const _SecurityNotice(
                'Security: enter the broker account number only. Never share a password, OTP, API secret or recovery code.',
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _openBroker(Map<String, dynamic> broker) async {
    final marketUuid = broker['broker_market_uuid']?.toString();
    if (marketUuid == null || marketUuid.isEmpty || _working) return;
    setState(() => _working = true);
    try {
      final response = await widget.apiClient.postJson(
        '/api/v1/copy-trade/broker-markets/$marketUuid/open-account-action',
        const {},
      );
      final data = _payload(response);
      final url = data['open_account_via_tradex_url']?.toString();
      final intent = data['onboarding_intent_uuid']?.toString();
      if (url == null || intent == null) {
        throw const ApiException(
          message: 'The broker onboarding action is unavailable.',
        );
      }
      if (!mounted) return;
      setState(() => _pendingIntents[marketUuid] = data);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw const ApiException(
          message: 'The broker link could not be opened.',
        );
      }
      _message(
        'After opening the LIVE account, return here and submit its account number.',
      );
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The broker link could not be opened right now.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showAccountForm(Map<String, dynamic> broker) async {
    final marketUuid = broker['broker_market_uuid']?.toString();
    final intent = _pendingIntents[marketUuid];
    if (marketUuid == null || intent == null) {
      _message('Open the TradeX partner link first.');
      return;
    }
    final account = TextEditingController();
    final key = GlobalKey<FormState>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071321),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit ${broker['broker_name'] ?? 'broker'} account',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${broker['market_category'] ?? ''} · LIVE · ${broker['required_currency'] ?? 'USD'}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: account,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 15,
                decoration: const InputDecoration(
                  labelText: 'Broker account number',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Account number is required.';
                  if (text.length > 15) return 'Use at most 15 digits.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (key.currentState?.validate() != true) return;
                    Navigator.pop(sheetContext, true);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit for verification'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Do not enter your broker password or OTP.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) {
      account.dispose();
      return;
    }

    setState(() => _working = true);
    try {
      await widget.apiClient.postJson('/api/v1/copy-trade/broker-accounts', {
        'onboarding_intent_uuid': intent['onboarding_intent_uuid'],
        'account_number': account.text.trim(),
      });
      _pendingIntents.remove(marketUuid);
      _message('Account submitted. TradeX will verify the IB relationship.');
      _reload();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      account.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showResubmitForm(Map<String, dynamic> accountData) async {
    final accountUuid = accountData['uuid']?.toString();
    if (accountUuid == null || accountUuid.isEmpty || _working) return;

    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071321),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Correct broker account number',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                accountData['status_reason']?.toString() ??
                    'TradeX requested a corrected account number.',
                style: const TextStyle(color: Color(0xFFFF9DA8)),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 15,
                decoration: const InputDecoration(
                  labelText: 'Correct account number',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Account number is required.'
                    : null,
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (key.currentState?.validate() == true) {
                      Navigator.pop(sheetContext, true);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Resubmit for verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) {
      controller.dispose();
      return;
    }

    setState(() => _working = true);
    try {
      await widget.apiClient.postJson(
        '/api/v1/copy-trade/broker-accounts/$accountUuid/resubmit',
        {'account_number': controller.text.trim()},
      );
      _message('Corrected account number submitted for verification.');
      _reload();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      controller.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Map<String, dynamic> _payload(Map<String, dynamic>? response) {
    final raw = response?['data'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from(response ?? const {});
  }

  Map<String, dynamic> _mapValue(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false)
      : const [];

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _CopyTradeHero extends StatelessWidget {
  const _CopyTradeHero({
    required this.ready,
    required this.nextStep,
    required this.premiumActive,
  });

  final bool ready;
  final String nextStep;
  final bool premiumActive;

  @override
  Widget build(BuildContext context) {
    final (title, message, icon, color) = switch (nextStep) {
      'COPY_TRADE_READY' => (
        'Copy Trade ready',
        'Your verified account passed the activation gates.',
        Icons.verified_rounded,
        const Color(0xFF19D6A3),
      ),
      'ACTIVATION_PENDING' => (
        'Eligibility review',
        'Broker verification is complete. Activation gates are pending.',
        Icons.rule_rounded,
        TradeXColors.gold,
      ),
      'WAITING_FOR_VERIFICATION' => (
        'Verification pending',
        'TradeX is checking your partner relationship and LIVE account.',
        Icons.hourglass_top_rounded,
        const Color(0xFF4EA4FF),
      ),
      'ACTION_REQUIRED' => (
        'Action required',
        'Review the account status below and resubmit when requested.',
        Icons.error_outline_rounded,
        const Color(0xFFFF6374),
      ),
      'EDUCATION_PREMIUM_REQUIRED' => (
        'Premium required',
        'Activate Education Premium before connecting a broker account.',
        Icons.workspace_premium_outlined,
        TradeXColors.gold,
      ),
      _ => (
        'Connect your account',
        'Open a supported account using the TradeX partner link.',
        Icons.link_rounded,
        const Color(0xFF4EA4FF),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2038), Color(0xFF06111D)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .6)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .12), blurRadius: 24),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  premiumActive ? 'PREMIUM ACTIVE' : 'PREMIUM INACTIVE',
                  style: TextStyle(
                    color: premiumActive
                        ? const Color(0xFF19D6A3)
                        : TradeXColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          if (ready) const Icon(Icons.check_circle, color: Color(0xFF19D6A3)),
        ],
      ),
    );
  }
}

class _CopyTradeMarketPicker extends StatelessWidget {
  const _CopyTradeMarketPicker({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values
          .map((value) {
            final active = selected == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(value == 'ALL' ? 'All' : value),
                selected: active,
                onSelected: (_) => onSelected(value),
                selectedColor: TradeXColors.gold,
                labelStyle: TextStyle(
                  color: active ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          })
          .toList(growable: false),
    ),
  );
}

class _CopyTradeHeading extends StatelessWidget {
  const _CopyTradeHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            color: TradeXColors.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
    ],
  );
}

class _CopyTradeAccountCard extends StatelessWidget {
  const _CopyTradeAccountCard({
    required this.account,
    required this.working,
    required this.onResubmit,
  });
  final Map<String, dynamic> account;
  final bool working;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final broker = account['broker'] is Map
        ? Map<String, dynamic>.from(account['broker'] as Map)
        : <String, dynamic>{};
    final activation = account['activation'] is Map
        ? Map<String, dynamic>.from(account['activation'] as Map)
        : <String, dynamic>{};
    final status = account['status']?.toString() ?? 'PENDING';
    final color = switch (status) {
      'ACTIVE' => const Color(0xFF19D6A3),
      'VERIFIED' => const Color(0xFF4EA4FF),
      'PENDING' || 'ESCALATED' => TradeXColors.gold,
      _ => const Color(0xFFFF6374),
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CopyTradeInitials(name: broker['name']?.toString() ?? 'Broker'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broker['name']?.toString() ?? 'Broker account',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${account['market_category'] ?? '—'} · ${account['account_number_masked'] ?? '—'}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: .5)),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CopyTradeStatusLine(
                  label: 'IB verification',
                  value: status == 'PENDING'
                      ? 'Under review'
                      : status.replaceAll('_', ' '),
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CopyTradeStatusLine(
                  label: 'Eligibility',
                  value:
                      activation['state']?.toString().replaceAll('_', ' ') ??
                      'NOT ELIGIBLE',
                  color: activation['copy_trade_ready'] == true
                      ? const Color(0xFF19D6A3)
                      : Colors.white60,
                ),
              ),
            ],
          ),
          if (account['status_reason'] != null) ...[
            const SizedBox(height: 10),
            Text(
              account['status_reason'].toString(),
              style: const TextStyle(color: Color(0xFFFF9DA8), fontSize: 12),
            ),
          ],
          if (status == 'NEEDS_RESUBMISSION') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: working ? null : onResubmit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Correct and resubmit'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyTradeStatusLine extends StatelessWidget {
  const _CopyTradeStatusLine({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CopyTradeBrokerCard extends StatelessWidget {
  const _CopyTradeBrokerCard({
    required this.broker,
    required this.hasIntent,
    required this.working,
    required this.onOpen,
    required this.onSubmit,
  });

  final Map<String, dynamic> broker;
  final bool hasIntent;
  final bool working;
  final VoidCallback onOpen;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF091726),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        _CopyTradeInitials(name: broker['broker_name']?.toString() ?? 'Broker'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                broker['broker_name']?.toString() ?? 'Supported broker',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${broker['market_category'] ?? '—'} · LIVE · ${broker['required_currency'] ?? 'USD'}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (hasIntent)
          FilledButton(
            onPressed: working ? null : onSubmit,
            child: const Text('Submit ID'),
          )
        else
          OutlinedButton(
            onPressed: working ? null : onOpen,
            child: const Text('Open'),
          ),
      ],
    ),
  );
}

class _CopyTradeInitials extends StatelessWidget {
  const _CopyTradeInitials({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD45C), Color(0xFFB77A10)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        initials.isEmpty ? 'TX' : initials,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CopyTradeEmpty extends StatelessWidget {
  const _CopyTradeEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF091522),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white60)),
        ),
      ],
    ),
  );
}

class _CopyTradeError extends StatelessWidget {
  const _CopyTradeError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          Text(
            error is ApiException
                ? (error as ApiException).message
                : 'Copy Trade details could not be loaded.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
