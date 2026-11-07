part of '../learn_module.dart';

class PremiumAccessScreen extends StatefulWidget {
  const PremiumAccessScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
}

class _PremiumAccessScreenState extends State<PremiumAccessScreen> {
  late Future<JsonMap> future = widget.repository.premiumAccess();
  String? selectedProductUuid;

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Premium Access',
    child: _FutureBody(
      future: future,
      onRetry: _reload,
      builder: (data) {
        final productsData = LearnRepository.map(data['products']);
        final activation = LearnRepository.map(data['activation']);
        final rawProducts =
            LearnRepository.list(productsData['items']).isNotEmpty
            ? LearnRepository.list(productsData['items'])
            : LearnRepository.list(productsData['products']);
        final products = _educationPremiumProducts(rawProducts);
        final selected = _selectedProduct(products);
        final active =
            LearnRepository.flag(activation['premium_active']) ||
            LearnRepository.flag(activation['is_active']);
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 44),
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/progress_ai_premium_ui/illustrations/premium_faceted_gold_bull_on_rock.png',
                      height: constraints.maxWidth < 340 ? 120 : 145,
                      width: constraints.maxWidth * .58,
                      fit: BoxFit.contain,
                      semanticLabel: 'Premium gold bull',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      right: constraints.maxWidth * .36,
                      bottom: 12,
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Upgrade to\nTradeX '),
                            TextSpan(
                              text: 'Premium',
                              style: TextStyle(color: _gold),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 25,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              active ? 'Your verified premium learning entitlement is active.' : 'Unlock the complete TradeX education experience with a verified premium entitlement.',
              style: TextStyle(
                color: context.palette.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (products.isEmpty)
              const _InfoCard(
                title: 'No offer available',
                body: 'TradeX has not published a purchasable education product for this account.',
              )
            else ...[
              if (products.length > 1)
                _ProductPlanSelector(
                  products: products,
                  selectedUuid: LearnRepository.text(selected['uuid']),
                  onSelected: (uuid) =>
                      setState(() => selectedProductUuid = uuid),
                ),
              if (products.length > 1) const SizedBox(height: 14),
              _PremiumPriceBlock(product: selected),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const ValueKey('education-premium-product-card'),
                onPressed: LearnRepository.text(selected['uuid']).isEmpty
                    ? null
                    : () =>
                          _openCheckout(LearnRepository.text(selected['uuid'])),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  active ? 'Manage Premium Access' : 'Subscribe securely',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: context.palette.gold,
                  foregroundColor: context.palette.primaryButtonText,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _PremiumBenefitsCard(
              description: LearnRepository.text(selected['description']),
            ),
            const SizedBox(height: 14),
            _PremiumVerificationStatus(activation: activation, active: active),
          ],
        );
      },
    ),
  );

  JsonMap _selectedProduct(List<JsonMap> products) {
    if (products.isEmpty) return <String, dynamic>{};
    final selected = selectedProductUuid;
    if (selected != null) {
      for (final product in products) {
        if (LearnRepository.text(product['uuid']) == selected) return product;
      }
    }
    return products.first;
  }

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

class _PremiumBenefitsCard extends StatelessWidget {
  const _PremiumBenefitsCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      children: [
        if (description.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              style: TextStyle(
                color: context.palette.secondaryText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: context.palette.border),
        ],
        const _PremiumBenefitRow(
          icon: Icons.school_outlined,
          title: 'Premium lessons',
          subtitle: 'Access is controlled by your verified entitlement.',
        ),
        Divider(color: context.palette.border),
        const _PremiumBenefitRow(
          icon: Icons.lock_outline_rounded,
          title: 'Secure checkout',
          subtitle: 'Continue through the existing TradeX payment flow.',
        ),
        Divider(color: context.palette.border),
        const _PremiumBenefitRow(
          icon: Icons.verified_user_outlined,
          title: 'Verified activation',
          subtitle: 'Lessons unlock only after payment confirmation.',
        ),
      ],
    ),
  );
}

class _PremiumBenefitRow extends StatelessWidget {
  const _PremiumBenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 42,
          child: Icon(icon, color: context.palette.gold, size: 27),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProductPlanSelector extends StatelessWidget {
  const _ProductPlanSelector({
    required this.products,
    required this.selectedUuid,
    required this.onSelected,
  });

  final List<JsonMap> products;
  final String selectedUuid;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        for (final product in products)
          ButtonSegment<String>(
            value: LearnRepository.text(product['uuid']),
            label: Text(_productPeriodLabel(product)),
          ),
      ],
      selected: {selectedUuid},
      onSelectionChanged: (selection) => onSelected(selection.first),
    ),
  );
}

class _PremiumPriceBlock extends StatelessWidget {
  const _PremiumPriceBlock({required this.product});

  final JsonMap product;

  @override
  Widget build(BuildContext context) {
    final price = LearnRepository.map(product['price']);
    final formatted = LearnRepository.text(product['formatted_price']);
    final amount = LearnRepository.text(price['amount']);
    final currency = LearnRepository.text(
      product['currency'],
      LearnRepository.text(price['currency']),
    );
    final displayPrice = formatted.isNotEmpty
        ? formatted
        : [currency, amount].where((value) => value.isNotEmpty).join(' ');
    final period = LearnRepository.text(
      product['billing_period'],
      LearnRepository.text(product['period']),
    );
    return Semantics(
      label: 'Premium price $displayPrice',
      child: Column(
        children: [
          Text(
            LearnRepository.text(product['name'], 'TradeX Education Premium'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: displayPrice.isEmpty
                      ? 'Price unavailable'
                      : displayPrice,
                ),
                if (period.isNotEmpty)
                  TextSpan(
                    text: ' / ${period.toLowerCase()}',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PremiumVerificationStatus extends StatelessWidget {
  const _PremiumVerificationStatus({
    required this.activation,
    required this.active,
  });

  final JsonMap activation;
  final bool active;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Row(
      children: [
        Icon(
          active ? Icons.verified_rounded : Icons.shield_outlined,
          color: context.palette.gold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Membership status',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                LearnRepository.text(
                  activation['status'],
                  active ? 'Active' : 'No active entitlement',
                ),
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<JsonMap> _educationPremiumProducts(List<dynamic> products) {
  final mapped = products
      .map(LearnRepository.map)
      .where((product) {
        final identity = [
          product['code'],
          product['name'],
          product['slug'],
        ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
        return identity.contains('education') && identity.contains('premium');
      })
      .toList(growable: false);
  if (mapped.isNotEmpty) return mapped;
  return products.map(LearnRepository.map).toList(growable: false);
}

String _productPeriodLabel(JsonMap product) {
  final period = LearnRepository.text(
    product['billing_period'],
    LearnRepository.text(product['period']),
  );
  if (period.isNotEmpty) return period;
  return LearnRepository.text(product['name'], 'Premium');
}
