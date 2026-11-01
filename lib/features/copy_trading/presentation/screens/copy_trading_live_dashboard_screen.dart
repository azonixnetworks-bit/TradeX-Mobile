part of '../copy_trading_module.dart';

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
