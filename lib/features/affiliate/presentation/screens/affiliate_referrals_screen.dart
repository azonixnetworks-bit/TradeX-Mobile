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
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReferralCubit(repository)..load(),
    child: _ReferralsBody(onUpgrade: onUpgrade),
  );
}

class _ReferralsBody extends StatelessWidget {
  const _ReferralsBody({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReferralCubit, ReferralState>(
      builder: (context, state) => AffiliateScaffold(
        title: 'My Referrals',
        subtitle: 'Your direct referral network and qualified sales.',
        onRefresh: context.read<ReferralCubit>().load,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: context.read<ReferralCubit>().search,
                    decoration: const InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<ReferralFilter>(
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
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: _fieldDecoration(),
                    child: const Icon(Icons.filter_list_rounded, color: _gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final entry in const [
                  (ReferralFilter.all, 'All'),
                  (ReferralFilter.qualified, 'Qualified'),
                  (ReferralFilter.noSale, 'No sale'),
                ]) ...[
                  Expanded(
                    child: _FilterButton(
                      label: entry.$2,
                      selected: state.filter == entry.$1,
                      onTap: () =>
                          context.read<ReferralCubit>().filter(entry.$1),
                    ),
                  ),
                  if (entry.$1 != ReferralFilter.noSale)
                    const SizedBox(width: 8),
                ],
              ],
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
              for (final referral in state.items) ...[
                ReferralTile(data: referral),
                const SizedBox(height: 10),
              ],
              if (state.page < state.lastPage)
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
        ),
      ),
    );
  }
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
    return SectionCard(
      padding: const EdgeInsets.all(14),
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
                  style: const TextStyle(color: _muted, fontSize: 12),
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
                color: qualified ? TradeXColors.success : TradeXColors.warning,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AffiliateArt(
                    path: _AffiliateAssets.gift,
                    fallback: Icons.card_giftcard_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$sales ${sales == 1 ? 'sale' : 'sales'}',
                    style: const TextStyle(color: _gold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
