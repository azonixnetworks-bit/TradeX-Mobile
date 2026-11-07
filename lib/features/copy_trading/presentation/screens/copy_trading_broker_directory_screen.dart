part of '../copy_trading_module.dart';

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
          !await AppPlatformRegistry.current.launchExternal(target)) {
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
          const CopyPageHeading(
            title: 'Choose Your',
            goldTitle: 'Broker',
            subtitle: 'Choose a configured broker to start your secure TradeX connection.',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 18),
          _MarketSelector(
            value: _market,
            onChanged: (value) => setState(() => _market = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available $_market brokers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${visible.length} configured',
                style: const TextStyle(
                  color: copyGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
