part of '../home_dashboard_screen.dart';

class _LiveTradeIdeasCarousel extends StatefulWidget {
  const _LiveTradeIdeasCarousel({
    required this.repository,
    required this.onActionTap,
  });

  final TradeIdeasRepository repository;
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

        return SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 16),
            itemCount: ideas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _LiveTradeIdeaCard(
              idea: ideas[index],
              position: index,
              repository: widget.repository,
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
      decoration: _panelDecoration(context),
      child: const Row(
        children: [
          Icon(
            Icons.insights_outlined,
            color: TradeXColors.goldBright,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'New TradeX market analysis will appear here as soon as it is published.',
              style: TextStyle(color: TradeXColors.secondaryText, height: 1.35),
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
  final TradeIdeasRepository repository;

  @override
  State<_LiveTradeIdeaCard> createState() => _LiveTradeIdeaCardState();
}

class _LiveTradeIdeaCardState extends State<_LiveTradeIdeaCard> {
  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    final directionColor = idea.direction == 'BUY'
        ? TradeXColors.success
        : idea.direction == 'SELL'
        ? TradeXColors.error
        : TradeXColors.goldBright;
    final label = switch (widget.position) {
      0 => 'LATEST',
      1 => 'RECENT',
      _ => 'PREVIOUS',
    };

    return Container(
      width: 306,
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
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TradeChartPreview(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.primaryText,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        idea.direction,
                        style: TextStyle(
                          color: directionColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SignalValue(label: 'Entry', value: idea.entry),
                      _SignalValue(label: 'SL', value: idea.stopLoss),
                      if (idea.targets.isNotEmpty)
                        _SignalValue(
                          label: idea.targets.first.label,
                          value: idea.targets.first.price,
                          valueColor: TradeXColors.success,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (idea.latestUpdate != null)
            Text(
              idea.latestUpdate!.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 10,
              ),
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
                border: Border.all(
                  color: TradeXColors.gold.withValues(alpha: .7),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 15,
                    color: TradeXColors.goldBright,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'View Analysis',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
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
  const _TradeChartPreview();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 126,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: const Color(0xFF0A1514),
        alignment: Alignment.center,
        child: const _MiniCandles(),
      ),
    ),
  );
}

class _SignalValue extends StatelessWidget {
  const _SignalValue({
    required this.label,
    required this.value,
    this.valueColor = TradeXColors.primaryText,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
