part of '../funded_advisor_module.dart';

class _FundedCompaniesScreen extends StatefulWidget {
  const _FundedCompaniesScreen();

  @override
  State<_FundedCompaniesScreen> createState() => _FundedCompaniesScreenState();
}

class _FundedCompaniesScreenState extends State<_FundedCompaniesScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FundedAdvisorCubit>().refreshIfDue();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FundedAdvisorCubit, FundedAdvisorState>(
    builder: (context, state) {
      final cubit = context.read<FundedAdvisorCubit>();
      if (!state.hasCatalog &&
          state.status != FundedAdvisorStatus.errorNoCache) {
        return const Scaffold(
          backgroundColor: TradeXColors.background,
          body: SafeArea(
            child: Center(child: CircularProgressIndicator(color: fundedGold)),
          ),
        );
      }
      return FundedPage(
        title: 'Funded Companies',
        subtitle: 'Discover and compare funded trading providers and published programs.',
        onRefresh: () => cubit.refreshIfDue(manual: true),
        actions: [
          FundedIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () => cubit.refreshIfDue(manual: true),
          ),
        ],
        children: [
          NoTradeZoneWarningBanner(
            source: context.read<NoTradeWarningSource>(),
          ),
          if (state.message != null) ...[
            FundedStatusNotice(message: state.message!),
            const SizedBox(height: 12),
          ],
          if (!state.hasCatalog)
            FundedEmptyState(
              title: 'Funded Advisor unavailable',
              message: state.message ?? 'No saved data is available yet.',
              action: 'Retry',
              onAction: () => cubit.refreshIfDue(manual: true),
            )
          else ...[
            TextField(
              onChanged: cubit.setQuery,
              decoration: InputDecoration(
                hintText: 'Search providers by name or offer',
                prefixIcon: const Icon(Icons.search_rounded, color: fundedGold),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FundedPill(
                  label: 'All',
                  selected: !state.featuredOnly,
                  onTap: () => cubit.setFeaturedOnly(false),
                ),
                FundedPill(
                  label: 'Featured',
                  selected: state.featuredOnly,
                  onTap: () => cubit.setFeaturedOnly(true),
                ),
                const FundedPill(label: 'A–Z'),
              ],
            ),
            const SizedBox(height: 20),
            FundedSectionTitle(
              title: state.featuredOnly
                  ? 'Featured Partners'
                  : 'Available Partners',
              subtitle: '${state.visiblePartners.length} verified listings',
            ),
            if (state.visiblePartners.isEmpty)
              const FundedEmptyState(
                title: 'No matching companies',
                message: 'Try another search or remove the featured filter.',
              )
            else
              for (final partner in state.visiblePartners) ...[
                _PartnerCard(
                  partner: partner,
                  onTap: () {
                    cubit.selectPartner(partner);
                    _open(context, const FundedCompanyDetailsScreen());
                  },
                ),
                const SizedBox(height: 12),
              ],
          ],
        ],
      );
    },
  );
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner, required this.onTap});

  final FundedPartner partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FundedCard(
    gold: partner.isFeatured,
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PartnerLogo(partner: partner, size: 58),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partner.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (partner.isFeatured)
                    const FundedPill(label: 'FEATURED', selected: true),
                ],
              ),
              if (partner.offerText != null) ...[
                const SizedBox(height: 6),
                Text(
                  partner.offerText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: fundedMuted, height: 1.35),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (partner.challengeTypes.isNotEmpty)
                    FundedPill(
                      label:
                          '${partner.challengeTypes.length} challenge type${partner.challengeTypes.length == 1 ? '' : 's'}',
                    ),
                  if (partner.rules.isNotEmpty)
                    FundedPill(label: '${partner.rules.length} news rules'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: fundedGold),
      ],
    ),
  );
}

class _PartnerLogo extends StatelessWidget {
  const _PartnerLogo({required this.partner, required this.size});

  final FundedPartner partner;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fundedGold.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TradeXColors.goldSoft),
      ),
      child: Text(
        partner.initials,
        style: const TextStyle(color: fundedGold, fontWeight: FontWeight.w900),
      ),
    );
    final logoUrl = partner.logoUrl;
    if (logoUrl == null) return fallback;
    return FutureBuilder<Uint8List>(
      future: context.read<FundedAdvisorCubit>().useCases.loadLogo(logoUrl),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            snapshot.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}
