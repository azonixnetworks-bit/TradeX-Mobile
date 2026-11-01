part of '../crypto_market_screen.dart';

class _CryptoTradeIdeasSection extends StatefulWidget {
  const _CryptoTradeIdeasSection({required this.repository});

  final DashboardTradeIdeasRepository repository;

  @override
  State<_CryptoTradeIdeasSection> createState() =>
      _CryptoTradeIdeasSectionState();
}

class _CryptoTradeIdeasSectionState extends State<_CryptoTradeIdeasSection> {
  late Future<List<DashboardTradeIdea>> _request;
  final PageController _pageController = PageController();
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.latestCrypto(limit: 5);
  }

  void _retry() {
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    setState(() {
      _currentPage = 0;
      _request = widget.repository.latestCrypto(limit: 5);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: _SectionHeading(
              title: 'Crypto Trade Ideas',
              subtitle: 'Recent signal · swipe for the previous 4',
            ),
          ),
          IconButton(
            tooltip: 'Refresh crypto trade ideas',
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<DashboardTradeIdea>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 184,
              child: Center(
                child: CircularProgressIndicator(
                  color: TradeXColors.goldBright,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return _CryptoTradeIdeasMessage(
              icon: Icons.cloud_off_rounded,
              message: 'Crypto trade ideas are temporarily unavailable.',
              onRetry: _retry,
            );
          }

          final ideas = (snapshot.data ?? const <DashboardTradeIdea>[])
              .where(
                (idea) => idea.category.isEmpty || idea.category == 'CRYPTO',
              )
              .take(5)
              .toList(growable: false);
          if (ideas.isEmpty) {
            return _CryptoTradeIdeasMessage(
              icon: Icons.lightbulb_outline_rounded,
              message: 'No crypto trade ideas are published right now.',
              onRetry: _retry,
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 184,
                child: PageView.builder(
                  key: const ValueKey('crypto-trade-ideas-carousel'),
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ideas.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) => _CryptoTradeIdeaCard(
                    idea: ideas[index],
                    position: index,
                    total: ideas.length,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < ideas.length; index++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _currentPage ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? TradeXColors.goldBright
                            : Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    if (index < ideas.length - 1) const SizedBox(width: 5),
                  ],
                  const SizedBox(width: 10),
                  Text(
                    '${_currentPage + 1} / ${ideas.length}',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _CryptoTradeIdeasMessage extends StatelessWidget {
  const _CryptoTradeIdeasMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF101925),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: TradeXColors.secondaryText, size: 28),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TradeXColors.secondaryText),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _CryptoTradeIdeaCard extends StatelessWidget {
  const _CryptoTradeIdeaCard({
    required this.idea,
    required this.position,
    required this.total,
  });

  final DashboardTradeIdea idea;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final direction = idea.direction.toUpperCase();
    final directionColor = direction == 'BUY'
        ? const Color(0xFF35D49A)
        : direction == 'SELL'
        ? const Color(0xFFFF626B)
        : TradeXColors.goldBright;
    final target = idea.targets.isEmpty ? '—' : idea.targets.first.price;
    final symbol = _tradeIdeaSymbol(idea.symbol);
    final segment = idea.symbol.trim().toUpperCase().endsWith('.P')
        ? 'FUTURES'
        : 'SPOT';
    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('crypto-trade-idea-${idea.uuid}'),
          onTap: symbol.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TradingViewChartScreen(
                      symbol: symbol,
                      segment: segment,
                    ),
                  ),
                ),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TradeXColors.surfaceRaised, TradeXColors.surface],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: directionColor.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: directionColor.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: directionColor.withValues(alpha: .45),
                        ),
                      ),
                      child: Text(
                        direction,
                        style: TextStyle(
                          color: directionColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        position == 0
                            ? 'RECENT SIGNAL'
                            : 'PREVIOUS ${position + 1} / $total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: position == 0
                              ? TradeXColors.goldBright
                              : TradeXColors.secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 7),
                Text(
                  idea.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (idea.instrumentName.isNotEmpty)
                  Text(
                    idea.instrumentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _TradeIdeaValue(label: 'ENTRY', value: idea.entry),
                    ),
                    Expanded(
                      child: _TradeIdeaValue(
                        label: 'STOP LOSS',
                        value: idea.stopLoss,
                      ),
                    ),
                    Expanded(
                      child: _TradeIdeaValue(
                        label: idea.targets.isEmpty
                            ? 'TARGET'
                            : idea.targets.first.label,
                        value: target,
                        color: const Color(0xFF35D49A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.candlestick_chart_rounded,
                      color: TradeXColors.goldBright,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Open TradingView chart',
                      style: TextStyle(
                        color: TradeXColors.goldBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: .5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TradeIdeaValue extends StatelessWidget {
  const _TradeIdeaValue({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TradeXColors.secondaryText,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

String _tradeIdeaSymbol(String raw) {
  var symbol = raw.trim().toUpperCase();
  if (symbol.contains(':')) symbol = symbol.split(':').last;
  if (symbol.endsWith('.P')) symbol = symbol.substring(0, symbol.length - 2);
  return symbol.replaceAll('/', '');
}
