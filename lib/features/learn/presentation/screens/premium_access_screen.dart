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
        final product = _educationPremiumProduct(items);
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
            if (product.isEmpty)
              const _InfoCard(
                title: 'No offer available',
                body: 'TradeX has not published a purchasable product for this account.',
              )
            else ...[
              _ProductOfferCard(product: product, onPurchase: _openCheckout),
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
    final subscribe = uuid.isEmpty ? null : () => onPurchase(uuid);
    return Semantics(
      button: subscribe != null,
      label: 'Subscribe to TradeX Education Premium',
      child: InkWell(
        key: const ValueKey('education-premium-product-card'),
        borderRadius: BorderRadius.circular(17),
        onTap: subscribe,
        child: _PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: TradeXColors.goldSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.school_rounded, color: _gold),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'TradeX Education Premium',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
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
                LearnRepository.text(
                  product['description'],
                  'Unlock the complete TradeX learning experience with verified premium access.',
                ),
                style: const TextStyle(color: TradeXColors.secondaryText),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PremiumBenefitChip(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Premium lessons',
                  ),
                  _PremiumBenefitChip(
                    icon: Icons.verified_user_outlined,
                    label: 'Secure checkout',
                  ),
                  _PremiumBenefitChip(
                    icon: Icons.all_inclusive_rounded,
                    label: 'Full course access',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: subscribe,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Subscribe securely'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an available payment method on the next secure screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TradeXColors.tertiaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBenefitChip extends StatelessWidget {
  const _PremiumBenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: TradeXColors.goldSoft,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _gold),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

JsonMap _educationPremiumProduct(List<dynamic> products) {
  for (final raw in products) {
    final product = LearnRepository.map(raw);
    final identity = [
      product['code'],
      product['name'],
      product['slug'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
    if (identity.contains('education') && identity.contains('premium')) {
      return product;
    }
  }
  return products.isEmpty
      ? <String, dynamic>{}
      : LearnRepository.map(products.first);
}
