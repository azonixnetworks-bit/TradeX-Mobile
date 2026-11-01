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
          title: 'Levels & Rewards',
          subtitle: 'Progress with every qualified paid sale.',
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
          borderColor: TradeXColors.gold,
          child: Column(
            children: [
              Row(
                children: [
                  _StageBadge(
                    code: AffiliateRepository.text(current['code'], 'STARTER'),
                    size: 76,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Level',
                          style: TextStyle(color: _muted),
                        ),
                        Text(
                          AffiliateRepository.text(
                            current['name'],
                            'Not started',
                          ),
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${AffiliateRepository.text(current['standard_commission_percent'], '0.00')}% commission',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (next.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Next Level',
                          style: TextStyle(color: _muted),
                        ),
                        Text(
                          AffiliateRepository.text(next['name']),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$nextTarget sales',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: _gold,
                  backgroundColor: TradeXColors.border,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$sales qualified sales'),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w800,
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
        const _SectionHeading(title: 'All Affiliate Levels'),
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
          _StageBadge(code: code),
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

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.code, this.size = 52});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = code.toUpperCase();
    final (color, icon) = switch (normalized) {
      'STARTER' => (const Color(0xFFCD7F32), Icons.stars_rounded),
      'GROWTH' => (const Color(0xFFC0C0C0), Icons.stars_rounded),
      'PRO' => (_gold, Icons.workspace_premium_rounded),
      'ELITE' => (const Color(0xFF248EFF), Icons.diamond_rounded),
      'DIAMOND' => (const Color(0xFF18CEDC), Icons.diamond_outlined),
      'AMBASSADOR' => (_purple, Icons.workspace_premium_outlined),
      _ => (const Color(0xFFFF5252), Icons.diamond_rounded),
    };
    final assetPath = switch (normalized) {
      'STARTER' || 'GROWTH' => _AffiliateAssets.trophy,
      'PRO' || 'AMBASSADOR' => _AffiliateAssets.crown,
      _ => null,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .14),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .2), blurRadius: 12),
        ],
      ),
      child: assetPath == null
          ? Icon(icon, color: color, size: size * .52)
          : Padding(
              padding: EdgeInsets.all(size * .12),
              child: _AffiliateArt(
                path: assetPath,
                fallback: icon,
                size: size * .72,
                tint: normalized == 'PRO' ? null : color,
              ),
            ),
    );
  }
}
