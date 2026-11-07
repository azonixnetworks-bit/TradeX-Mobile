part of '../affiliate_module.dart';

class AffiliateLevelsScreen extends StatelessWidget {
  const AffiliateLevelsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;

  Future<JsonMap> _load() async {
    final values = await Future.wait([
      repository.overview(),
      repository.stages(),
      repository.milestones(),
    ]);
    return {
      'overview': values[0],
      'stages': values[1],
      'milestones': values[2],
    };
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AffiliateLoadCubit(_load)..load(),
    child: Builder(
      builder: (context) => BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
        builder: (context, state) => AffiliateScaffold(
          title: 'Affiliate Milestones',
          subtitle: 'Grow your referrals and earnings to unlock higher levels.',
          onRefresh: context.read<AffiliateLoadCubit>().load,
          child: AffiliateStateBody(
            state: state,
            onRetry: context.read<AffiliateLoadCubit>().load,
            onUpgrade: onUpgrade,
            builder: (data) => LevelsContent(data: data),
          ),
        ),
      ),
    ),
  );
}

class LevelsContent extends StatelessWidget {
  const LevelsContent({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final overview = AffiliateRepository.mapOf(data['overview']);
    final current = AffiliateRepository.mapOf(overview['current_stage']);
    final next = AffiliateRepository.mapOf(overview['next_stage']);
    final stagesData = AffiliateRepository.mapOf(data['stages']);
    final stages = AffiliateRepository.listOf(stagesData['items']);
    final milestones = AffiliateRepository.mapOf(overview['milestones']);
    final nextMilestone = AffiliateRepository.mapOf(milestones['next']);
    final sales = AffiliateRepository.integer(
      overview['qualified_sales_count'],
    );
    final nextTarget = AffiliateRepository.integer(
      next['starts_at_qualified_sales'],
    );
    final progress = nextTarget <= 0
        ? 1.0
        : (sales / nextTarget).clamp(0.0, 1.0);
    final currentCode = AffiliateRepository.text(current['code'], '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          borderColor: context.palette.gold.withValues(alpha: .65),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    _AffiliateAssets.milestoneStar,
                    width: 82,
                    height: 82,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Level',
                          style: TextStyle(
                            color: context.palette.goldText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          AffiliateRepository.text(
                            current['name'],
                            'Not started',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${AffiliateRepository.text(current['standard_commission_percent'], '0.00')}% commission',
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
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  color: context.palette.gold,
                  backgroundColor: context.palette.surfaceMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      next.isEmpty
                          ? '$sales qualified sales · Maximum level reached'
                          : '$sales of $nextTarget qualified sales to ${AffiliateRepository.text(next['name'])}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: context.palette.goldText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (AffiliateRepository.boolean(milestones['eligible']) &&
            nextMilestone.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            borderColor: TradeXColors.goldSoft,
            child: Row(
              children: [
                const _GoldIcon(Icons.card_giftcard_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AffiliateRepository.integer(nextMilestone['remaining_qualified_sales'])} more qualified sales to ${AffiliateRepository.moneyText(nextMilestone['gift'])} milestone gift',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const _SectionHeading(title: 'Affiliate Levels'),
        const SizedBox(height: 10),
        if (stages.isNotEmpty)
          _AffiliateLevelTracker(
            stages: stages,
            sales: sales,
            currentCode: currentCode,
          ),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'Level Rewards'),
        const SizedBox(height: 10),
        if (stages.isEmpty)
          const _EmptyCard(message: 'No affiliate levels are configured.')
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < stages.length; index++) ...[
                  StageTile(
                    data: stages[index],
                    sales: sales,
                    currentCode: currentCode,
                  ),
                  if (index != stages.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AffiliateLevelTracker extends StatelessWidget {
  const _AffiliateLevelTracker({
    required this.stages,
    required this.sales,
    required this.currentCode,
  });

  final List<JsonMap> stages;
  final int sales;
  final String currentCode;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < stages.length; index++) ...[
            _LevelTrackerNode(
              data: stages[index],
              index: index,
              sales: sales,
              currentCode: currentCode,
            ),
            if (index != stages.length - 1)
              Container(
                width: 30,
                height: 3,
                margin: const EdgeInsets.only(top: 24),
                color: _stageAchieved(stages[index], sales)
                    ? context.palette.gold
                    : context.palette.border,
              ),
          ],
        ],
      ),
    ),
  );
}

class _LevelTrackerNode extends StatelessWidget {
  const _LevelTrackerNode({
    required this.data,
    required this.index,
    required this.sales,
    required this.currentCode,
  });

  final JsonMap data;
  final int index;
  final int sales;
  final String currentCode;

  @override
  Widget build(BuildContext context) {
    final code = AffiliateRepository.text(data['code'], '');
    final current = code == currentCode;
    final achieved = _stageAchieved(data, sales);
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          AnimatedContainer(
            duration: TradeXMotion.quick,
            width: current ? 54 : 48,
            height: current ? 54 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: achieved
                  ? context.palette.gold
                  : context.palette.surfaceMuted,
              border: Border.all(
                color: current
                    ? context.palette.goldText
                    : context.palette.borderStrong,
                width: current ? 2 : 1,
              ),
            ),
            child: Icon(
              current
                  ? Icons.star_rounded
                  : achieved
                  ? Icons.check_rounded
                  : Icons.lock_outline_rounded,
              color: achieved
                  ? context.palette.primaryButtonText
                  : context.palette.tertiaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'L${index + 1}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          Text(
            AffiliateRepository.text(data['name'], ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: current
                  ? context.palette.goldText
                  : context.palette.secondaryText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

bool _stageAchieved(JsonMap data, int sales) {
  final range = AffiliateRepository.mapOf(data['qualified_sales_range']);
  return sales >= AffiliateRepository.integer(range['min']);
}

class StageTile extends StatelessWidget {
  const StageTile({
    super.key,
    required this.data,
    required this.sales,
    required this.currentCode,
  });
  final JsonMap data;
  final int sales;
  final String currentCode;

  @override
  Widget build(BuildContext context) {
    final code = AffiliateRepository.text(data['code'], '');
    final range = AffiliateRepository.mapOf(data['qualified_sales_range']);
    final min = AffiliateRepository.integer(range['min']);
    final max = range['max'] == null
        ? null
        : AffiliateRepository.integer(range['max']);
    final milestone = AffiliateRepository.mapOf(data['milestone']);
    final current = code == currentCode;
    final achieved = sales >= min;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: current ? Border.all(color: _gold, width: 1.5) : null,
        color: current ? const Color(0x1AFFC83D) : Colors.transparent,
      ),
      child: Row(
        children: [
          Opacity(
            opacity: achieved ? 1 : .48,
            child: Image.asset(
              _AffiliateAssets.milestoneGift,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        AffiliateRepository.text(data['name']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      const StatusChip(label: 'Current', color: _gold),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  max == null ? '$min+ sales' : '$min - $max sales',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AffiliateRepository.text(data['standard_commission_percent'], '0.00')}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (AffiliateRepository.money(milestone['gift']) > 0)
                Text(
                  AffiliateRepository.moneyText(milestone['gift']),
                  style: const TextStyle(color: _gold, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            current
                ? Icons.radio_button_checked
                : achieved
                ? Icons.check_circle_outline
                : Icons.lock_outline,
            color: current || achieved ? _gold : _muted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
