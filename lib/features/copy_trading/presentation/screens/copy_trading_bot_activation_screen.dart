part of '../copy_trading_module.dart';

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
          const CopyPageHeading(
            title: 'Copy Bot',
            goldTitle: 'Activation',
            subtitle: 'Review your verified account and activation readiness securely.',
            icon: Icons.smart_toy_outlined,
          ),
          const SizedBox(height: 18),
          CopySectionCard(
            highlight: true,
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
          const SizedBox(height: 16),
          CopySectionCard(
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
                            'cTrader Copy Bot',
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
          const SizedBox(height: 18),
          const CopySectionHeading(
            title: 'Activation Checklist',
            subtitle: 'Only verified backend capabilities are shown.',
          ),
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
