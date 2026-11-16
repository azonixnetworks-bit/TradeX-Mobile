part of '../trade_idea_details_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.repository});
  final TradeIdeaDetail detail;
  final TradeIdeaRepositoryContract repository;
  @override
  Widget build(BuildContext context) {
    final idea = detail.summary;
    final buy = idea.direction == 'BUY';
    final palette = context.palette;
    final accent = buy ? palette.success : palette.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              Expanded(
                child: Text(
                  'Trade Idea Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _share(context, repository, detail),
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              MarketInstrumentAvatar(
                market: idea.category,
                symbol: idea.symbol,
                size: 68,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_displayCategory(idea.category)}  •  ${idea.timeframe}',
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      idea.instrumentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: TradeXRadii.control,
                  border: Border.all(color: accent),
                ),
                child: Text(
                  idea.direction,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
