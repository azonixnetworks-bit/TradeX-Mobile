part of '../investment_module.dart';

class MyInvestmentsScreen extends StatefulWidget {
  const MyInvestmentsScreen({super.key, required this.repository});

  final InvestmentRepository repository;

  @override
  State<MyInvestmentsScreen> createState() => _MyInvestmentsScreenState();
}

class _MyInvestmentsScreenState extends State<MyInvestmentsScreen> {
  late Future<InvestmentDashboard> _request;
  String _query = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _request = widget.repository.loadDashboard();
  }

  void _retry() =>
      setState(() => _request = widget.repository.loadDashboard(refresh: true));

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'My Investments',
    child: FutureBuilder<InvestmentDashboard>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _InvestmentLoading();
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InvestmentUnavailable(
                message: _investmentError(snapshot.error),
                onRetry: _retry,
              ),
            ],
          );
        }
        final investments =
            snapshot.data?.investments ?? const <CustomerInvestment>[];
        final needle = _query.trim().toLowerCase();
        final visible = investments
            .where((item) {
              final matchesQuery =
                  needle.isEmpty ||
                  item.code.toLowerCase().contains(needle) ||
                  item.productName.toLowerCase().contains(needle);
              final matchesFilter =
                  _filter == 'all' ||
                  _investmentStatusLabel(item.status) == _filter;
              return matchesQuery && matchesFilter;
            })
            .toList(growable: false);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: _investmentText),
              decoration: InputDecoration(
                hintText: 'Search code or investment product',
                hintStyle: const TextStyle(color: _investmentMuted),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: _investmentCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const ['all', 'active', 'pending', 'matured', 'closed']
                  .map(
                    (filter) => ChoiceChip(
                      label: Text(
                        filter[0].toUpperCase() + filter.substring(1),
                      ),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            _InvestmentSectionTitle(
              'Your investments',
              trailing: Text(
                '${visible.length.toString().padLeft(2, '0')} records',
                style: const TextStyle(
                  color: TradeXColors.goldBright,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const _InvestmentEmpty()
            else
              for (final investment in visible) ...[
                _InvestmentPreviewCard(
                  investment: investment,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InvestmentDetailsScreen(
                        repository: widget.repository,
                        investmentId: investment.id,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 6),
            const _InvestmentCard(
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: TradeXColors.goldBright),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Read-only investment records\nChoose an investment to review verified status, records and documents.',
                      style: TextStyle(color: _investmentMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
