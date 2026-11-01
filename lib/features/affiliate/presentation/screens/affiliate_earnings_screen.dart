part of '../affiliate_module.dart';

class AffiliateEarningsScreen extends StatefulWidget {
  const AffiliateEarningsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;

  @override
  State<AffiliateEarningsScreen> createState() =>
      _AffiliateEarningsScreenState();
}

class _AffiliateEarningsScreenState extends State<AffiliateEarningsScreen> {
  int months = 1;

  Future<JsonMap> _load() async {
    final overview = await widget.repository.overview();
    final values = await Future.wait([
      _optional(
        widget.repository.earningsSeries(months: months == 0 ? 12 : months),
      ),
      _optional(widget.repository.commissions(perPage: 20)),
    ]);
    return {
      'overview': overview,
      'series': values[0],
      'commissions': values[1],
    };
  }

  Future<JsonMap> _optional(Future<JsonMap> request) async {
    try {
      return await request;
    } catch (_) {
      return const {};
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(months),
    create: (_) => AffiliateLoadCubit(_load)..load(),
    child: Builder(
      builder: (context) => BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
        builder: (context, state) => AffiliateScaffold(
          title: 'Earnings & Sales',
          subtitle: 'Track commission income and qualified sales.',
          showBrand: false,
          onRefresh: context.read<AffiliateLoadCubit>().load,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in const [
                      (1, 'This Month'),
                      (3, 'Last 3 Months'),
                      (6, 'Last 6 Months'),
                      (0, 'All'),
                    ]) ...[
                      _FilterButton(
                        label: option.$2,
                        selected: months == option.$1,
                        onTap: () => setState(() => months = option.$1),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AffiliateStateBody(
                state: state,
                onRetry: context.read<AffiliateLoadCubit>().load,
                onUpgrade: widget.onUpgrade,
                builder: (data) => EarningsContent(data: data),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EarningsContent extends StatelessWidget {
  const EarningsContent({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final overview = AffiliateRepository.mapOf(data['overview']);
    final financials = AffiliateRepository.mapOf(overview['financials']);
    final commission = AffiliateRepository.mapOf(overview['commission']);
    final series = AffiliateRepository.mapOf(data['series']);
    final points = AffiliateRepository.listOf(series['items']);
    final commissionsData = AffiliateRepository.mapOf(data['commissions']);
    final entries = AffiliateRepository.listOf(commissionsData['items']);
    final sales = AffiliateRepository.integer(
      overview['qualified_sales_count'],
    );
    final rate = AffiliateRepository.text(
      commission['next_sale_rate_percent'],
      '0.00',
    );
    return Column(
      children: [
        SectionCard(
          borderColor: TradeXColors.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _AffiliateArt(
                    path: _AffiliateAssets.money,
                    fallback: Icons.stacked_line_chart_rounded,
                    size: 56,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total Commission Earned',
                      style: _sectionTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AffiliateRepository.moneyText(
                  financials['lifetime_commission_earned'],
                ),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(height: 210, child: EarningsChart(points: points)),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 10, height: 10, color: _gold),
                    const SizedBox(width: 6),
                    const Text(
                      'Net commission',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      AffiliateRepository.text(points.first['label']),
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–', style: TextStyle(color: _muted)),
                    ),
                    Text(
                      AffiliateRepository.text(points.last['label']),
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AffiliateMetricCard(
                width: double.infinity,
                label: 'Qualified Sales',
                value: '$sales',
                icon: Icons.shopping_cart_outlined,
                assetPath: _AffiliateAssets.gift,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AffiliateMetricCard(
                width: double.infinity,
                label: 'Commission Rate',
                value: '$rate%',
                icon: Icons.percent_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'Recent Commissions'),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const _EmptyCard(message: 'No commission records yet.')
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  CommissionTile(data: entries[index]),
                  if (index != entries.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key, required this.points});
  final List<JsonMap> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0x80101818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TradeXColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.query_stats_rounded,
                color: TradeXColors.goldSoft,
                size: 38,
              ),
              SizedBox(height: 10),
              Text(
                'Earnings activity will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your summary cards remain available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return CustomPaint(painter: _EarningsChartPainter(points));
  }
}

class _EarningsChartPainter extends CustomPainter {
  _EarningsChartPainter(this.points);
  final List<JsonMap> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((item) => AffiliateRepository.money(item['net_commission']))
        .toList(growable: false);
    final maxValue = math.max(1.0, values.fold<double>(0, math.max));
    final gap = 6.0;
    final width = math.max(
      4.0,
      (size.width - gap * (values.length - 1)) / values.length,
    );
    final baseline = size.height - 24;
    final grid = Paint()..color = TradeXColors.border;
    for (var index = 0; index < 4; index++) {
      final y = index * baseline / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final bar = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [TradeXColors.goldDeep, _gold],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < values.length; index++) {
      final height = values[index] / maxValue * (baseline - 10);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(index * (width + gap), baseline - height, width, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, bar);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class CommissionTile extends StatelessWidget {
  const CommissionTile({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final status = AffiliateRepository.text(data['status']);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const _GoldIcon(Icons.receipt_long_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission #${AffiliateRepository.integer(data['qualified_ordinal'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _date(data['earned_at']),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${AffiliateRepository.moneyText(data['net_commission'])}',
                style: const TextStyle(
                  color: TradeXColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${AffiliateRepository.text(data['rate_percent'], '0.00')}% · $status',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
