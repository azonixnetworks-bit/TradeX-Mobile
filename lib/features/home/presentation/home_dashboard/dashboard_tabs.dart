part of '../home_dashboard_screen.dart';

class _LearnTab extends StatelessWidget {
  const _LearnTab({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) =>
      LearnHomeScreen(repository: LearnDependencies(apiClient).repository);
}

class _TradeIdeasTab extends StatelessWidget {
  const _TradeIdeasTab({
    super.key,
    required this.onActionTap,
    required this.apiClient,
  });

  final ValueChanged<String> onActionTap;
  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _EntitlementAwareTab(
      apiClient: apiClient,
      title: 'Trade Ideas',
      introduction: 'Explore TradeX market-analysis tools. Protected prices, levels, charts and full analysis are requested only after the server confirms your membership.',
      protectedFeatures: [featureById('trade-idea-details')],
      activeBuilder: (_) => TradeIdeasScreen(
        repository: TradeIdeasDependencies(apiClient).repository,
        warningSource: MarketNewsWarningSource(MarketNewsRepository(apiClient)),
      ),
    );
  }
}

class _AffiliateTab extends StatelessWidget {
  const _AffiliateTab({
    super.key,
    required this.onActionTap,
    required this.apiClient,
  });

  final ValueChanged<String> onActionTap;
  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return AffiliateDashboardScreen(
      repository: AffiliateDependencies(apiClient).repository,
      onNotifications: () => onActionTap('notifications'),
      onUpgrade: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PremiumAccessScreen(
            repository: LearnDependencies(apiClient).repository,
          ),
        ),
      ),
      onConfigurePayoutMethod: (code) {
        final method = switch (code) {
          'PAYPAL' => WithdrawalMethod.paypal,
          'BINANCE' => WithdrawalMethod.binance,
          'USDT_TRC20' => WithdrawalMethod.usdtTrc20,
          _ => WithdrawalMethod.localBank,
        };
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                WithdrawalMethodScreen(apiClient: apiClient, method: method),
          ),
        );
      },
    );
  }
}

class _EntitlementAwareTab extends StatefulWidget {
  const _EntitlementAwareTab({
    required this.apiClient,
    required this.title,
    required this.introduction,
    required this.protectedFeatures,
    this.activeBuilder,
  });

  final TradeXApiClient apiClient;
  final String title;
  final String introduction;
  final List<FeatureSpec> protectedFeatures;
  final WidgetBuilder? activeBuilder;

  @override
  State<_EntitlementAwareTab> createState() => _EntitlementAwareTabState();
}

class _EntitlementAwareTabState extends State<_EntitlementAwareTab> {
  late Future<bool> _status = _loadStatus();
  late Future<JsonMap> _products = LearnDependencies(widget.apiClient)
      .repository
      .products();

  Future<bool> _loadStatus() async {
    final response = await widget.apiClient.getJson(
      '/api/v1/payments/activation-status',
    );
    final data = response['data'];
    return data is Map && data['premium_active'] == true;
  }

  void _reload() => setState(() {
    _status = _loadStatus();
    _products = LearnDependencies(widget.apiClient).repository.products();
  });

  @override
  Widget build(BuildContext context) => BlocFutureBuilder<bool>(
    future: _status,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: CircularProgressIndicator(color: TradeXColors.goldBright),
        );
      }
      if (snapshot.data == true && widget.protectedFeatures.length == 1) {
        if (widget.activeBuilder != null) {
          return widget.activeBuilder!(context);
        }
        return TradeXFeatureScreen(
          apiClient: widget.apiClient,
          spec: widget.protectedFeatures.first,
        );
      }
      return _ProtectedFeaturePreview(
        title: widget.title,
        introduction: widget.introduction,
        statusUnavailable: snapshot.hasError,
        premiumActive: snapshot.data == true,
        products: _products,
        features: widget.protectedFeatures,
        onOpen: _openProtected,
        onRetry: _reload,
      );
    },
  );

  Future<void> _openProtected(FeatureSpec feature) async {
    var active = false;
    try {
      active = await _loadStatus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An internet connection is required to verify premium access.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (!active) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PremiumAccessScreen(
            repository: LearnDependencies(widget.apiClient).repository,
          ),
        ),
      );
      if (!mounted) return;
      try {
        active = await _loadStatus();
      } catch (_) {
        active = false;
      }
    }
    if (!mounted) return;
    if (active) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder:
              widget.activeBuilder ??
              (_) => TradeXFeatureScreen(
                apiClient: widget.apiClient,
                spec: feature,
              ),
        ),
      );
    }
    if (mounted) _reload();
  }
}

class _ProtectedFeaturePreview extends StatelessWidget {
  const _ProtectedFeaturePreview({
    required this.title,
    required this.introduction,
    required this.statusUnavailable,
    required this.premiumActive,
    required this.products,
    required this.features,
    required this.onOpen,
    required this.onRetry,
  });

  final String title;
  final String introduction;
  final bool statusUnavailable;
  final bool premiumActive;
  final Future<JsonMap> products;
  final List<FeatureSpec> features;
  final ValueChanged<FeatureSpec> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(introduction, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        BlocFutureBuilder<JsonMap>(
          future: products,
          builder: (context, snapshot) {
            final items = LearnRepository.list(snapshot.data?['items']);
            if (items.isEmpty) return const SizedBox.shrink();
            final product = LearnRepository.map(items.first);
            final price = LearnRepository.map(product['price']);
            final amount = [
              LearnRepository.text(price['currency']),
              LearnRepository.text(price['amount']),
            ].where((part) => part.isNotEmpty).join(' ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_rounded,
                    color: TradeXColors.goldBright,
                  ),
                  title: Text(
                    LearnRepository.text(product['name'], 'TradeX membership'),
                  ),
                  subtitle: Text(
                    [
                      amount,
                      LearnRepository.text(product['description']),
                    ].where((part) => part.isNotEmpty).join(' • '),
                  ),
                ),
              ),
            );
          },
        ),
        if (statusUnavailable)
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_rounded),
              title: const Text('Membership status unavailable'),
              subtitle: const Text(
                'Program information remains available. Reconnect to verify protected access.',
              ),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        const _RiskNotice(),
        const SizedBox(height: 16),
        Text(
          premiumActive
              ? 'Your available membership features'
              : 'Protected membership features',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(feature.icon)),
                title: Text(feature.title),
                subtitle: Text(feature.subtitle),
                trailing: Icon(
                  premiumActive
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                ),
                onTap: () => onOpen(feature),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'No referral totals, earnings, trade levels or charts are stored in this preview. TradeX requests them only from the authorized backend.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
