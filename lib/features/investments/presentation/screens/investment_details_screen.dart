part of '../investment_module.dart';

class InvestmentDetailsScreen extends StatelessWidget {
  const InvestmentDetailsScreen({
    super.key,
    required this.repository,
    required this.investmentId,
  });

  final InvestmentRepository repository;
  final String investmentId;

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'Investment Details',
    child: FutureBuilder<InvestmentDashboard>(
      future: repository.loadInvestment(investmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _InvestmentLoading();
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InvestmentUnavailable(message: _investmentError(snapshot.error)),
            ],
          );
        }
        final investments =
            snapshot.data?.investments ?? const <CustomerInvestment>[];
        CustomerInvestment? investment;
        for (final item in investments) {
          if (item.id == investmentId) {
            investment = item;
            break;
          }
        }
        if (investment == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: _InvestmentEmpty(
              title: 'Investment unavailable',
              message: 'The requested investment record was not returned by the server.',
            ),
          );
        }
        final record = investment;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _InvestmentCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_bitcoin_rounded,
                    color: TradeXColors.goldBright,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.code,
                          style: const TextStyle(
                            color: _investmentText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          record.productName,
                          style: const TextStyle(color: _investmentMuted),
                        ),
                      ],
                    ),
                  ),
                  _InvestmentStatusBadge(_investmentStatusLabel(record.status)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Overview'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfitPerformanceScreen(
                          repository: repository,
                          investmentId: investmentId,
                        ),
                      ),
                    ),
                    child: const Text('Performance'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => InvestmentTransactionsScreen(
                          repository: repository,
                          investmentId: investmentId,
                        ),
                      ),
                    ),
                    child: const Text('Transactions'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => InvestmentAgreementsRiskScreen(
                          repository: repository,
                          investmentId: investmentId,
                        ),
                      ),
                    ),
                    child: const Text('Documents'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Investment Overview'),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Column(
                children: [
                  _InvestmentKeyValue(
                    label: 'Deposit amount',
                    value: _money(record.amount, record.currency),
                  ),
                  _InvestmentKeyValue(
                    label: 'Deposit network',
                    value: record.network ?? '—',
                  ),
                  _InvestmentKeyValue(
                    label: 'Investment period',
                    value: record.periodLabel ?? '—',
                  ),
                  _InvestmentKeyValue(
                    label: 'Start date',
                    value: _date(record.startAt),
                  ),
                  _InvestmentKeyValue(
                    label: 'Maturity date',
                    value: _date(record.maturityAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Profit & Settlement'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Customer share',
                    value: record.customerSharePercent == null
                        ? '—'
                        : '${record.customerSharePercent!.toStringAsFixed(0)}%',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Company share',
                    value: record.companySharePercent == null
                        ? '—'
                        : '${record.companySharePercent!.toStringAsFixed(0)}%',
                    icon: Icons.business_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InvestmentMetric(
                    label: 'High-water mark',
                    value: _money(record.highWaterMark, record.currency),
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Loss carry-forward',
                    value: _money(record.lossCarryForward, record.currency),
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Column(
                children: [
                  _InvestmentKeyValue(
                    label: 'Principal settlement',
                    value: record.principalSettlementStatus == null
                        ? '—'
                        : _recordStatusLabel(record.principalSettlementStatus!),
                  ),
                  _InvestmentKeyValue(
                    label: 'Payout wallet',
                    value: record.payoutWalletStatus == null
                        ? '—'
                        : _recordStatusLabel(record.payoutWalletStatus!),
                  ),
                  _InvestmentKeyValue(
                    label: 'Wallet address',
                    value: record.maskedPayoutWallet ?? 'Restricted',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Investment Lifecycle'),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final step in record.lifecycle)
                    SizedBox(
                      width: 84,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: step.completed
                                ? _investmentGreen
                                : step.current
                                ? TradeXColors.goldBright
                                : const Color(0xFF3B3D42),
                            child: Icon(
                              step.completed
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              color: step.current
                                  ? _investmentBackground
                                  : _investmentText,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _investmentMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (record.lifecycle.isEmpty)
                    const Text(
                      'Lifecycle has not been provided by the server.',
                      style: TextStyle(color: _investmentMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _InvestmentRiskNotice(
              'Current value, payout and settlement are subject to verified records and agreement terms.',
            ),
          ],
        );
      },
    ),
  );
}
