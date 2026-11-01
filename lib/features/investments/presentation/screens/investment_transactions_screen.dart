part of '../investment_module.dart';

class InvestmentTransactionsScreen extends StatefulWidget {
  const InvestmentTransactionsScreen({
    super.key,
    required this.repository,
    this.investmentId,
  });

  final InvestmentRepository repository;
  final String? investmentId;

  @override
  State<InvestmentTransactionsScreen> createState() =>
      _InvestmentTransactionsScreenState();
}

class _InvestmentTransactionsScreenState
    extends State<InvestmentTransactionsScreen> {
  String _type = 'all';
  String _status = 'all';

  Future<InvestmentDashboard> _load() => widget.investmentId == null
      ? widget.repository.loadDashboard()
      : widget.repository.loadInvestment(widget.investmentId!);

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'Transactions & Payouts',
    child: FutureBuilder<InvestmentDashboard>(
      future: _load(),
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
        final transactions =
            snapshot.data?.transactions ?? const <InvestmentTransaction>[];
        final visible = transactions
            .where((item) {
              final typeMatches =
                  _type == 'all' ||
                  item.type.toLowerCase().replaceAll(' ', '_') == _type;
              final statusMatches =
                  _status == 'all' ||
                  _recordStatusLabel(item.status) == _status;
              return typeMatches && statusMatches;
            })
            .toList(growable: false);
        final currency = transactions.isEmpty
            ? snapshot.data?.portfolio.currency
            : transactions.first.currency;
        double totalFor(String type) => transactions
            .where(
              (item) => item.type.toLowerCase().replaceAll(' ', '_') == type,
            )
            .fold(0, (sum, item) => sum + (item.amount ?? 0));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Deposits',
                    value: _money(totalFor('deposit'), currency),
                    icon: Icons.south_west_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Profit payouts',
                    value: _money(totalFor('profit_payout'), currency),
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Top-ups',
                    value: _money(totalFor('top_up'), currency),
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Principal settled',
                    value: _money(totalFor('principal_settlement'), currency),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              dropdownColor: _investmentCard,
              decoration: const InputDecoration(labelText: 'Transaction type'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All types')),
                DropdownMenuItem(value: 'deposit', child: Text('Deposits')),
                DropdownMenuItem(
                  value: 'profit_payout',
                  child: Text('Profit payouts'),
                ),
                DropdownMenuItem(value: 'top_up', child: Text('Top-ups')),
                DropdownMenuItem(
                  value: 'principal_settlement',
                  child: Text('Principal'),
                ),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              dropdownColor: _investmentCard,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All statuses')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'verified', child: Text('Verified')),
                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Transaction History'),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              const _InvestmentEmpty(
                title: 'No transactions',
                message: 'Verified deposits and payouts will appear when the server provides them.',
              )
            else
              for (final transaction in visible) ...[
                _InvestmentCard(
                  onTap: () => _showTransaction(context, transaction),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_vert_rounded,
                        color: TradeXColors.goldBright,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.type,
                              style: const TextStyle(
                                color: _investmentText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${transaction.reference} · ${transaction.network ?? '—'} · ${_date(transaction.createdAt)}',
                              style: const TextStyle(
                                color: _investmentMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _money(transaction.amount, transaction.currency),
                            style: const TextStyle(
                              color: _investmentText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _InvestmentStatusBadge(
                            _recordStatusLabel(transaction.status),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    ),
  );

  void _showTransaction(
    BuildContext context,
    InvestmentTransaction transaction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _investmentCard,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.reference,
                      style: const TextStyle(
                        color: _investmentText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _InvestmentStatusBadge(
                    _recordStatusLabel(transaction.status),
                  ),
                ],
              ),
              _InvestmentKeyValue(label: 'Type', value: transaction.type),
              _InvestmentKeyValue(
                label: 'Blockchain TX ID',
                value: transaction.maskedTransactionHash ?? 'Restricted',
              ),
              _InvestmentKeyValue(
                label: 'Payout wallet',
                value: transaction.maskedWallet ?? 'Restricted',
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Internal reference',
                      style: TextStyle(color: _investmentMuted),
                    ),
                  ),
                  Text(
                    transaction.reference,
                    style: const TextStyle(
                      color: _investmentText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (transaction.referenceCopyAllowed)
                    IconButton(
                      tooltip: 'Copy internal reference',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: transaction.reference),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                ],
              ),
              const Text(
                'Sensitive IDs and wallet addresses are masked by default.',
                style: TextStyle(color: _investmentMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
