part of '../investment_module.dart';

class ProfitPerformanceScreen extends StatefulWidget {
  const ProfitPerformanceScreen({
    super.key,
    required this.repository,
    this.investmentId,
  });

  final InvestmentRepository repository;
  final String? investmentId;

  @override
  State<ProfitPerformanceScreen> createState() =>
      _ProfitPerformanceScreenState();
}

class _ProfitPerformanceScreenState extends State<ProfitPerformanceScreen> {
  String _window = '3M';

  Future<InvestmentDashboard> _load() => widget.investmentId == null
      ? widget.repository.loadDashboard()
      : widget.repository.loadInvestment(widget.investmentId!);

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'Profit Performance',
    child: FutureBuilder<InvestmentDashboard>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _InvestmentLoading();
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InvestmentUnavailable(message: _investmentError(snapshot.error)),
            ],
          );
        }
        final data = snapshot.data!;
        final verified = data.profitPeriods
            .where((period) => period.verified)
            .toList(growable: false);
        final verifiedProfit = verified.fold<double>(
          0,
          (sum, item) => sum + (item.grossProfitLoss ?? 0),
        );
        final firstVerified = _firstOrNull(verified);
        final currency = firstVerified?.currency ?? data.portfolio.currency;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Verified profit',
                    value: verified.isEmpty
                        ? '—'
                        : _money(verifiedProfit, currency),
                    icon: Icons.trending_up_rounded,
                    positive: verified.isNotEmpty && verifiedProfit > 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Customer share',
                    value: _money(
                      verified.fold<double>(
                        0,
                        (sum, item) => sum + (item.customerShare ?? 0),
                      ),
                      currency,
                    ),
                    icon: Icons.person_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InvestmentMetric(
                    label: 'Company share',
                    value: _money(
                      verified.fold<double>(
                        0,
                        (sum, item) => sum + (item.companyShare ?? 0),
                      ),
                      currency,
                    ),
                    icon: Icons.business_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvestmentMetric(
                    label: 'High-water mark',
                    value: _money(firstVerified?.highWaterMark, currency),
                    icon: Icons.change_history_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Performance Overview'),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Portfolio value',
                    style: TextStyle(
                      color: _investmentText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final window in const [
                        '1M',
                        '3M',
                        '6M',
                        'YTD',
                        'ALL',
                      ])
                        ChoiceChip(
                          label: Text(window),
                          selected: _window == window,
                          onSelected: (_) => setState(() => _window = window),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (verified.isEmpty)
                    const _InvestmentEmpty(
                      title: 'No verified performance',
                      message: 'Performance appears only after the server returns approved, verified periods.',
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        painter: _InvestmentPerformancePainter(verified),
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Profit Periods'),
            const SizedBox(height: 10),
            if (data.profitPeriods.isEmpty)
              const _InvestmentEmpty(
                title: 'No profit periods',
                message: 'No performance periods were returned by the server.',
              )
            else
              for (final period in data.profitPeriods) ...[
                _InvestmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              period.label,
                              style: const TextStyle(
                                color: _investmentText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _InvestmentStatusBadge(
                            _recordStatusLabel(period.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InvestmentKeyValue(
                        label: 'Period',
                        value:
                            '${_date(period.openedAt)} – ${_date(period.closedAt)}',
                      ),
                      _InvestmentKeyValue(
                        label: 'Opening',
                        value: _money(period.openingValue, period.currency),
                      ),
                      _InvestmentKeyValue(
                        label: 'Closing',
                        value: _money(period.closingValue, period.currency),
                      ),
                      _InvestmentKeyValue(
                        label: 'Gross P/L',
                        value: period.verified
                            ? _money(period.grossProfitLoss, period.currency)
                            : 'Pending verification',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            const _InvestmentRiskNotice(
              'Past performance does not guarantee future results.',
            ),
          ],
        );
      },
    ),
  );
}

class _InvestmentPerformancePainter extends CustomPainter {
  _InvestmentPerformancePainter(this.periods);

  final List<InvestmentProfitPeriod> periods;

  @override
  void paint(Canvas canvas, Size size) {
    final values = periods
        .map((item) => item.closingValue)
        .whereType<double>()
        .toList(growable: false);
    if (values.length < 2) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height -
          ((values[index] - minValue) / range) * (size.height - 20) -
          10;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = TradeXColors.goldBright
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _InvestmentPerformancePainter oldDelegate) =>
      oldDelegate.periods != periods;
}
