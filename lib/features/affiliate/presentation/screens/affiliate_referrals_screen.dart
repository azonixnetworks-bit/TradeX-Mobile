part of '../affiliate_module.dart';

class AffiliateReferralsScreen extends StatelessWidget {
  const AffiliateReferralsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
  });

  final AffiliateRepository repository;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ReferralCubit(repository)..load()),
      BlocProvider(
        create: (_) => AffiliateLoadCubit(repository.overview)..load(),
      ),
    ],
    child: _ReferralsBody(onUpgrade: onUpgrade),
  );
}

class _ReferralsBody extends StatelessWidget {
  const _ReferralsBody({required this.onUpgrade});
  final VoidCallback onUpgrade;

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<ReferralCubit>().load(),
      context.read<AffiliateLoadCubit>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReferralCubit, ReferralState>(
      builder: (context, state) => AffiliateScaffold(
        title: 'Direct Referrals',
        subtitle: 'Users who joined TradeX using your referral link.',
        onRefresh: () => _refresh(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
              builder: (context, overviewState) =>
                  _ReferralOverview(state: overviewState),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: context.read<ReferralCubit>().search,
              decoration: InputDecoration(
                hintText: 'Search referred users…',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.palette.secondaryText,
                ),
                suffixIcon: PopupMenuButton<ReferralFilter>(
                  tooltip: 'Filter referrals',
                  initialValue: state.filter,
                  onSelected: context.read<ReferralCubit>().filter,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: ReferralFilter.all,
                      child: Text('All referrals'),
                    ),
                    PopupMenuItem(
                      value: ReferralFilter.qualified,
                      child: Text('Qualified'),
                    ),
                    PopupMenuItem(
                      value: ReferralFilter.noSale,
                      child: Text('No qualified sale'),
                    ),
                  ],
                  icon: const Icon(Icons.filter_list_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in const [
                    (ReferralFilter.all, 'All'),
                    (ReferralFilter.qualified, 'Qualified'),
                    (ReferralFilter.noSale, 'No sale'),
                  ]) ...[
                    _FilterButton(
                      label: entry.$2,
                      selected: state.filter == entry.$1,
                      onTap: () =>
                          context.read<ReferralCubit>().filter(entry.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.status == AffiliateLoadStatus.loading &&
                state.items.isEmpty)
              const LoadingSkeleton()
            else if (state.status == AffiliateLoadStatus.premium)
              PremiumGate(message: state.message, onUpgrade: onUpgrade)
            else if (state.status == AffiliateLoadStatus.failure)
              _ErrorCard(
                message: state.message ?? 'Unable to load referrals.',
                onRetry: context.read<ReferralCubit>().load,
              )
            else if (state.items.isEmpty)
              const _EmptyCard(
                message: 'No direct referrals match this filter.',
              )
            else ...[
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < state.items.length;
                      index++
                    ) ...[
                      ReferralTile(data: state.items[index]),
                      if (index != state.items.length - 1)
                        Divider(height: 1, color: context.palette.border),
                    ],
                  ],
                ),
              ),
              if (state.page < state.lastPage) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.loadingMore
                      ? null
                      : context.read<ReferralCubit>().loadMore,
                  icon: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more'),
                ),
              ],
            ],
            const SizedBox(height: 18),
            BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
              builder: (context, overviewState) {
                final referral = AffiliateRepository.mapOf(
                  overviewState.data['referral'],
                );
                final url = AffiliateRepository.text(referral['url'], '');
                if (url.isEmpty) return const SizedBox.shrink();
                return _ShareReferralButton(
                  onPressed: () => _nativeShare(context, url),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralOverview extends StatelessWidget {
  const _ReferralOverview({required this.state});

  final AffiliateLoadState state;

  @override
  Widget build(BuildContext context) {
    if (state.status != AffiliateLoadStatus.ready) {
      return const SizedBox.shrink();
    }
    final referral = AffiliateRepository.mapOf(state.data['referral']);
    final totalValue = referral['direct_referrals_count'];
    final qualifiedValue = state.data['qualified_sales_count'];
    final metrics = <(String, Object?, IconData)>[
      if (totalValue != null)
        ('Total Referred', totalValue, Icons.people_alt_outlined),
      if (qualifiedValue != null)
        ('Qualified Sales', qualifiedValue, Icons.check_circle_outline),
    ];
    if (metrics.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(
              child: _ReferralStat(
                label: metrics[index].$1,
                value: '${AffiliateRepository.integer(metrics[index].$2)}',
                icon: metrics[index].$3,
              ),
            ),
            if (index != metrics.length - 1)
              Container(width: 1, height: 56, color: context.palette.border),
          ],
        ],
      ),
    );
  }
}

class _ReferralStat extends StatelessWidget {
  const _ReferralStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: context.palette.gold, size: 25),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.secondaryText, fontSize: 11),
      ),
    ],
  );
}

class _ShareReferralButton extends StatelessWidget {
  const _ShareReferralButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [context.palette.gold, const Color(0xFFB57A0A)],
      ),
      borderRadius: BorderRadius.circular(15),
    ),
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Image.asset(
        _AffiliateAssets.referralLinkBadge,
        width: 27,
        height: 27,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
      label: const Text('Share Referral Link'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: context.palette.primaryButtonText,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class ReferralTile extends StatelessWidget {
  const ReferralTile({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final name = AffiliateRepository.text(data['name']);
    final qualification = AffiliateRepository.mapOf(data['qualification']);
    final qualified = AffiliateRepository.boolean(
      qualification['has_qualified_sale'],
    );
    final sales = AffiliateRepository.integer(
      qualification['active_qualified_sales_count'],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          _InitialAvatar(name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_date(data['joined_at'])}',
                  style: TextStyle(
                    color: context.palette.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: qualified ? 'Qualified' : 'No sale',
                color: qualified
                    ? context.palette.success
                    : context.palette.warning,
              ),
              const SizedBox(height: 6),
              Text(
                '$sales ${sales == 1 ? 'sale' : 'sales'}',
                style: TextStyle(color: context.palette.gold, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
