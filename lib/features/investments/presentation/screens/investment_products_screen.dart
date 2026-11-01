part of '../investment_module.dart';

class InvestmentProductsScreen extends StatelessWidget {
  const InvestmentProductsScreen({super.key, required this.repository});

  final InvestmentRepository repository;

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'Available Products',
    child: FutureBuilder<InvestmentDashboard>(
      future: repository.loadDashboard(),
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
        final products = snapshot.data?.products ?? const <InvestmentProduct>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text(
              'Explore investment products',
              style: TextStyle(
                color: _investmentText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Availability, product terms, and eligibility are provided by TradeX.',
              style: TextStyle(color: _investmentMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              const _InvestmentEmpty(
                title: 'No investment products available',
                message: 'Products will appear only after the server publishes customer availability.',
              )
            else
              for (final product in products) ...[
                _InvestmentProductCard(product),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 6),
            const _InvestmentRiskNotice(
              'Investment involves risk. No profits or returns are guaranteed.',
            ),
          ],
        );
      },
    ),
  );
}

class _InvestmentProductCard extends StatelessWidget {
  const _InvestmentProductCard(this.product);

  final InvestmentProduct product;

  @override
  Widget build(BuildContext context) {
    final available = product.availability == InvestmentAvailability.active;
    return _InvestmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.diamond_outlined,
                color: TradeXColors.goldBright,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: available ? _investmentText : _investmentMuted,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (product.description != null)
                      Text(
                        product.description!,
                        style: const TextStyle(color: _investmentMuted),
                      ),
                  ],
                ),
              ),
              _InvestmentStatusBadge(switch (product.availability) {
                InvestmentAvailability.active => 'Active',
                InvestmentAvailability.comingSoon => 'Coming soon',
                InvestmentAvailability.unavailable => 'Unavailable',
              }),
            ],
          ),
          const SizedBox(height: 12),
          _InvestmentKeyValue(
            label: 'Deposit currency',
            value: product.currencies.isEmpty
                ? 'Not provided'
                : product.currencies.join(' · '),
          ),
          _InvestmentKeyValue(
            label: 'Supported network',
            value: product.networks.isEmpty
                ? 'Not provided'
                : product.networks.join(' · '),
          ),
          _InvestmentKeyValue(
            label: 'Profit-sharing model',
            value: product.profitSharingModel ?? 'Not provided',
          ),
          _InvestmentKeyValue(
            label: 'Investment period',
            value: product.periodTerms ?? 'Not provided',
          ),
          _InvestmentKeyValue(
            label: 'Risk level',
            value: product.riskTier ?? 'Not assessed',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: available
                  ? () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: _investmentCard,
                      showDragHandle: true,
                      builder: (_) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  color: _investmentText,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                product.description ?? 'No additional product details were provided.',
                                style: const TextStyle(
                                  color: _investmentMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _InvestmentRiskNotice(
                                'Read-only product information. Investment actions are not available in this app.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,
              child: Text(available ? 'View Details' : 'Unavailable'),
            ),
          ),
        ],
      ),
    );
  }
}
