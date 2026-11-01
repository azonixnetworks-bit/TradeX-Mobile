part of '../learn_module.dart';

class PremiumAccessScreen extends StatefulWidget {
  const PremiumAccessScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
}

class _PremiumAccessScreenState extends State<PremiumAccessScreen> {
  late Future<JsonMap> future = widget.repository.premiumAccess();

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Premium Access',
    child: _FutureBody(
      future: future,
      onRetry: _reload,
      builder: (data) {
        final products = LearnRepository.map(data['products']);
        final activation = LearnRepository.map(data['activation']);
        final items = LearnRepository.list(products['items']).isNotEmpty
            ? LearnRepository.list(products['items'])
            : LearnRepository.list(products['products']);
        return ListView(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: _gold, size: 72),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Membership status',
              body: LearnRepository.text(
                activation['status'],
                LearnRepository.flag(activation['premium_active']) ||
                        LearnRepository.flag(activation['is_active'])
                    ? 'Active'
                    : 'No active entitlement',
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const _InfoCard(
                title: 'No offer available',
                body: 'TradeX has not published a purchasable product for this account.',
              )
            else
              for (final raw in items) ...[
                _ProductOfferCard(
                  product: LearnRepository.map(raw),
                  onPurchase: _openCheckout,
                ),
                const SizedBox(height: 12),
              ],
            const _InfoCard(
              title: 'Verified access only',
              body: 'Premium lessons unlock only after TradeX confirms payment and the education API returns an active entitlement.',
            ),
          ],
        );
      },
    ),
  );

  void _reload() {
    setState(() {
      future = widget.repository.premiumAccess();
    });
  }

  Future<void> _openCheckout(String productUuid) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentCheckoutScreen(
          apiClient: widget.repository.paymentGateway,
          productUuid: productUuid,
        ),
      ),
    );
    if (mounted) _reload();
  }
}

class _ProductOfferCard extends StatelessWidget {
  const _ProductOfferCard({required this.product, required this.onPurchase});
  final JsonMap product;
  final ValueChanged<String> onPurchase;

  @override
  Widget build(BuildContext context) {
    final uuid = LearnRepository.text(product['uuid']);
    final price = LearnRepository.map(product['price']);
    final amount = LearnRepository.text(
      product['formatted_price'],
      LearnRepository.text(price['amount']),
    );
    final currency = LearnRepository.text(
      product['currency'],
      LearnRepository.text(price['currency']),
    );
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LearnRepository.text(product['name'], 'TradeX membership'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (amount.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$currency $amount'.trim(),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            LearnRepository.text(product['description']),
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: uuid.isEmpty ? null : () => onPurchase(uuid),
            child: const Text('Choose payment method'),
          ),
        ],
      ),
    );
  }
}
