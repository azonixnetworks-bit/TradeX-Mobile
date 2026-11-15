part of '../home_dashboard_screen.dart';

class _LiveTradeIdeasCarousel extends StatefulWidget {
  const _LiveTradeIdeasCarousel({
    required this.repository,
    required this.onActionTap,
  });

  final DashboardTradeIdeasRepository repository;
  final ValueChanged<String> onActionTap;

  @override
  State<_LiveTradeIdeasCarousel> createState() =>
      _LiveTradeIdeasCarouselState();
}

class _LiveTradeIdeasCarouselState extends State<_LiveTradeIdeasCarousel> {
  late Future<List<DashboardTradeIdea>> _ideas;

  @override
  void initState() {
    super.initState();
    _ideas = widget.repository.latestThree();
  }

  @override
  Widget build(BuildContext context) {
    return BlocFutureBuilder<List<DashboardTradeIdea>>(
      future: _ideas,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 230,
            child: Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            ),
          );
        }

        final ideas = snapshot.data ?? const <DashboardTradeIdea>[];
        if (ideas.isEmpty) {
          return _NoTradeIdeasCard(
            onTap: () => widget.onActionTap('Trade ideas'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 535,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: ideas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: constraints.maxWidth,
                child: _LiveTradeIdeaCard(
                  idea: ideas[index],
                  position: index,
                  repository: widget.repository,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoTradeIdeasCard extends StatelessWidget {
  const _NoTradeIdeasCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      height: 146,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(context).copyWith(color: Colors.white),
      child: Row(
        children: [
          Icon(
            Icons.insights_outlined,
            color: context.palette.goldText,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'New TradeX market analysis will appear here as soon as it is published.',
              style: TextStyle(
                color: context.palette.secondaryText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LiveTradeIdeaCard extends StatefulWidget {
  const _LiveTradeIdeaCard({
    required this.idea,
    required this.position,
    required this.repository,
  });

  final DashboardTradeIdea idea;
  final int position;
  final DashboardTradeIdeasRepository repository;

  @override
  State<_LiveTradeIdeaCard> createState() => _LiveTradeIdeaCardState();
}

class _LiveTradeIdeaCardState extends State<_LiveTradeIdeaCard> {
  late Future<Uint8List?> _chartBytes;

  @override
  void initState() {
    super.initState();
    _chartBytes = widget.repository.chartBytes(widget.idea);
  }

  @override
  void didUpdateWidget(covariant _LiveTradeIdeaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idea.uuid != widget.idea.uuid) {
      _chartBytes = widget.repository.chartBytes(widget.idea);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    final palette = context.palette;
    final directionColor = idea.direction == 'BUY'
        ? palette.success
        : idea.direction == 'SELL'
        ? palette.error
        : palette.goldText;
    final label = switch (widget.position) {
      0 => 'LATEST',
      1 => 'RECENT',
      _ => 'PREVIOUS',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallPill(label: label, color: TradeXColors.goldBright),
              const Spacer(),
              Text(
                idea.timeframe,
                style: TextStyle(
                  color: const Color(0xFF686868),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TradeChartPreview(chartBytes: _chartBytes),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (idea.instrumentName.isNotEmpty)
                      Text(
                        idea.instrumentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6E6E6E),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: directionColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: directionColor.withValues(alpha: .55),
                  ),
                ),
                child: Text(
                  idea.direction,
                  style: TextStyle(
                    color: directionColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.gold.withValues(alpha: .36)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SignalValue(label: 'Entry', value: idea.entry),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SignalValue(label: 'SL', value: idea.stopLoss),
                ),
              ],
            ),
          ),
          if (idea.targets.isNotEmpty) ...[
            const SizedBox(height: 7),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: idea.targets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final target = idea.targets[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TradeXColors.success.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: TradeXColors.success.withValues(alpha: .35),
                      ),
                    ),
                    child: Text(
                      '${target.label}: ${target.price}',
                      style: const TextStyle(
                        color: Color(0xFF167A4A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (idea.latestUpdate != null)
            Text(
              idea.latestUpdate!.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF686868), fontSize: 10),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ReactionButton(
                icon: Icons.thumb_up_alt_outlined,
                count: idea.likesCount,
                selected: idea.viewerReaction == 'LIKE',
                onTap: () => _react(idea, 'LIKE'),
              ),
              const SizedBox(width: 10),
              _ReactionButton(
                icon: Icons.thumb_down_alt_outlined,
                count: idea.dislikesCount,
                selected: idea.viewerReaction == 'DISLIKE',
                onTap: () => _react(idea, 'DISLIKE'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => TradeIdeaDetailsScreen(
                  repository: widget.repository.detailsRepository,
                  uuid: idea.uuid,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: palette.gold.withValues(alpha: .7)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 15,
                    color: palette.goldText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'View Analysis',
                    style: TextStyle(
                      color: palette.goldText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _react(DashboardTradeIdea idea, String reaction) async {
    final previous = idea.viewerReaction;
    final next = previous == reaction ? null : reaction;
    setState(() => idea.applyReaction(next));
    try {
      final summary = await widget.repository.react(idea, next);
      if (mounted) setState(() => idea.applyReactionSummary(summary));
    } catch (_) {
      if (mounted) {
        setState(() => idea.applyReaction(previous));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save your reaction.')),
        );
      }
    }
  }
}

class _TradeChartPreview extends StatelessWidget {
  const _TradeChartPreview({required this.chartBytes});

  final Future<Uint8List?> chartBytes;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 185,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List?>(
        future: chartBytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return Image.memory(
              bytes,
              key: const ValueKey('latest-trade-idea-laravel-chart'),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            );
          }
          return ColoredBox(
            color: const Color(0xFFFFFCF5),
            child: Center(
              child: Icon(
                Icons.candlestick_chart_rounded,
                color: context.palette.goldText,
                size: 44,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _SignalValue extends StatelessWidget {
  const _SignalValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF747474), fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
