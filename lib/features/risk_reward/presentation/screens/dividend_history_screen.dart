part of '../risk_reward_module.dart';

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
    child: _CalculatorCanvas(
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
              const _CalculatorHero(
                eyebrow: 'PAYMENT TIMELINE',
                title: 'Dividend History',
                subtitle: 'Track verified payments, ex-dividend dates and upcoming payouts.',
              ),
              const SizedBox(height: 18),
              _GoldCard(
                child: Row(
                  children: [
                    _DividendStockBadge(symbol: data.symbol, size: 66),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.symbol,
                            style: TextStyle(
                              color: context.palette.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            data.companyName,
                            style: TextStyle(
                              color: context.palette.secondaryText,
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
    ),
  );
}
