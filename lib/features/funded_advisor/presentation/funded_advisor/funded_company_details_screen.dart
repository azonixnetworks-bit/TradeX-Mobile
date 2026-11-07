part of '../funded_advisor_module.dart';

class FundedCompanyDetailsScreen extends StatelessWidget {
  const FundedCompanyDetailsScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FundedAdvisorCubit, FundedAdvisorState>(
    builder: (context, state) {
      final partner = state.selectedPartner;
      if (partner == null) return const _MissingPartnerPage();
      return FundedPage(
        title: 'Company Details',
        subtitle: 'Review provider information, available programs and terms.',
        children: [
          NoTradeZoneWarningBanner(
            source: context.read<NoTradeWarningSource>(),
            applicableSymbolsOrCurrencies: _partnerWarningScope(partner),
          ),
          FundedCard(
            gold: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PartnerLogo(partner: partner, size: 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${partner.challengeTypes.length} program option${partner.challengeTypes.length == 1 ? '' : 's'} · ${partner.accountSizes.length} account size${partner.accountSizes.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (partner.isFeatured) ...[
                        const SizedBox(height: 8),
                        const FundedPill(
                          label: 'TRADEX FEATURED PARTNER',
                          selected: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LinkGrid(partner: partner),
          const SizedBox(height: 14),
          FundedCard(
            gold: true,
            onTap: () => _open(context, const FundedNoTradeRulesScreen()),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: fundedGold, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Trade Zone',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'View live high-impact news warnings and this company\'s official restrictions.',
                        style: TextStyle(
                          color: fundedMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: fundedGold),
              ],
            ),
          ),
          if (partner.offerText != null) ...[
            const SizedBox(height: 14),
            FundedCard(
              gold: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_offer_outlined, color: fundedGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      partner.offerText!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const FundedSectionTitle(
            title: 'Provider Programs',
            subtitle: 'All values below come from the funded catalog',
          ),
          _ValueSection(
            icon: Icons.flag_outlined,
            title: 'Supported countries',
            values: partner.supportedCountries,
            emptyText: 'Country availability is not published.',
          ),
          const SizedBox(height: 10),
          _ValueSection(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Account sizes',
            values: partner.accountSizes,
            emptyText: 'Account sizes are not published.',
          ),
          const SizedBox(height: 10),
          _ValueSection(
            icon: Icons.layers_outlined,
            title: 'Challenge types',
            values: partner.challengeTypes,
            emptyText: 'Challenge types are not published.',
          ),
          if (partner.disclosure != null) ...[
            const SizedBox(height: 14),
            FundedCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: fundedGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      partner.disclosure!,
                      style: const TextStyle(color: fundedMuted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          FundedPrimaryButton(
            label: 'Choose Account Options',
            icon: Icons.arrow_forward_rounded,
            onPressed:
                partner.challengeTypes.isEmpty || partner.accountSizes.isEmpty
                ? null
                : () => _open(context, const FundedAccountOptionsScreen()),
          ),
        ],
      );
    },
  );
}

class _LinkGrid extends StatelessWidget {
  const _LinkGrid({required this.partner});

  final FundedPartner partner;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (partner.websiteUrl != null)
            _LinkTile(
              width: width,
              icon: Icons.language_rounded,
              label: 'Official Website',
              onTap: () => _launch(partner.websiteUrl!),
            ),
          if (partner.affiliateUrl != null)
            _LinkTile(
              width: width,
              icon: Icons.open_in_new_rounded,
              label: 'TradeX Partner Link',
              onTap: () => _launch(partner.affiliateUrl!),
            ),
          if (partner.promoCode != null)
            _LinkTile(
              width: width,
              icon: Icons.copy_rounded,
              label: partner.promoCode!,
              onTap: () {
                Clipboard.setData(ClipboardData(text: partner.promoCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Promo code copied.')),
                );
              },
            ),
        ],
      );
    },
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: FundedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fundedGold),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ValueSection extends StatelessWidget {
  const _ValueSection({
    required this.icon,
    required this.title,
    required this.values,
    required this.emptyText,
  });

  final IconData icon;
  final String title;
  final List<String> values;
  final String emptyText;

  @override
  Widget build(BuildContext context) => FundedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: fundedGold),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (values.isEmpty)
          Text(emptyText, style: const TextStyle(color: fundedMuted))
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map((value) => FundedPill(label: value)).toList(),
          ),
      ],
    ),
  );
}
