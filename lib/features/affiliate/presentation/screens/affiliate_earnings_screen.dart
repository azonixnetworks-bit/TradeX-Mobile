part of '../affiliate_module.dart';

class AffiliateEarningsScreen extends StatefulWidget {
  const AffiliateEarningsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
    required this.onConfigurePayoutMethod,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigurePayoutMethod;

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
      _optional(widget.repository.payoutSummary()),
    ]);
    return {
      'overview': overview,
      'series': values[0],
      'commissions': values[1],
      'payout': values[2],
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
          title: 'Your Earnings',
          subtitle: 'Track your commissions, qualified sales, and payouts.',
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
                builder: (data) => EarningsContent(
                  data: data,
                  onRequestPayout: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => AffiliatePayoutsScreen(
                        repository: widget.repository,
                        onUpgrade: widget.onUpgrade,
                        onConfigureMethod: widget.onConfigurePayoutMethod,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EarningsContent extends StatelessWidget {
  const EarningsContent({
    super.key,
    required this.data,
    required this.onRequestPayout,
  });
  final JsonMap data;
  final VoidCallback onRequestPayout;

  @override
  Widget build(BuildContext context) {
    final overview = AffiliateRepository.mapOf(data['overview']);
    final financials = AffiliateRepository.mapOf(overview['financials']);
    final commission = AffiliateRepository.mapOf(overview['commission']);
    final series = AffiliateRepository.mapOf(data['series']);
    final points = AffiliateRepository.listOf(series['items']);
    final commissionsData = AffiliateRepository.mapOf(data['commissions']);
    final entries = AffiliateRepository.listOf(commissionsData['items']);
    final payout = AffiliateRepository.mapOf(data['payout']);
    final sales = AffiliateRepository.integer(
      overview['qualified_sales_count'],
    );
    final rate = AffiliateRepository.text(
      commission['next_sale_rate_percent'],
      '0.00',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0B540), Color(0xFFB77805)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: context.palette.gold.withValues(alpha: .2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AffiliateRepository.moneyText(
                        financials['lifetime_commission_earned'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Total Commission Earned',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Image.asset(
                _AffiliateAssets.earningsCoins,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
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
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Earnings Activity', style: _sectionTitle),
              const SizedBox(height: 14),
              SizedBox(height: 190, child: EarningsChart(points: points)),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 10, height: 10, color: _gold),
                    const SizedBox(width: 6),
                    Text(
                      'Net commission',
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AffiliateRepository.text(points.first['label']),
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–'),
                    ),
                    Text(
                      AffiliateRepository.text(points.last['label']),
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
                    Divider(height: 1, color: context.palette.border),
                ],
              ],
            ),
          ),
        if (payout.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            onTap: onRequestPayout,
            borderColor: context.palette.gold.withValues(alpha: .55),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: context.palette.gold,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout Summary',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Available to payout',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  AffiliateRepository.moneyText(payout['available']),
                  style: TextStyle(
                    color: context.palette.goldText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GoldActionButton(label: 'Request Payout', onPressed: onRequestPayout),
        ],
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
    return CustomPaint(
      painter: _EarningsChartPainter(
        points,
        lineColor: context.palette.gold,
        gridColor: context.palette.border,
      ),
    );
  }
}

class _EarningsChartPainter extends CustomPainter {
  _EarningsChartPainter(
    this.points, {
    required this.lineColor,
    required this.gridColor,
  });
  final List<JsonMap> points;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((item) => AffiliateRepository.money(item['net_commission']))
        .toList(growable: false);
    final maxValue = math.max(1.0, values.fold<double>(0, math.max));
    final baseline = size.height - 12;
    final grid = Paint()..color = gridColor;
    for (var index = 0; index < 4; index++) {
      final y = index * baseline / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final coordinates = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : index * size.width / (values.length - 1);
      final y = baseline - values[index] / maxValue * (baseline - 12);
      coordinates.add(Offset(x, y));
    }
    final linePath = Path()..moveTo(coordinates.first.dx, coordinates.first.dy);
    for (final point in coordinates.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(coordinates.last.dx, baseline)
      ..lineTo(coordinates.first.dx, baseline)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: .32),
            lineColor.withValues(alpha: .02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in coordinates) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
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
