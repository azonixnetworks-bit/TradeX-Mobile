part of '../trade_idea_details_screen.dart';

class _TradeSetup extends StatelessWidget {
  const _TradeSetup({required this.detail});
  final TradeIdeaDetail detail;
  @override
  Widget build(BuildContext context) {
    final idea = detail.summary;
    return _Panel(
      title: 'Trade Setup',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          _DetailRow(label: 'Entry Zone', value: idea.entry.display),
          _DetailRow(
            label: 'Stop Loss',
            value: idea.stopLoss.display,
            color: TradeXColors.error,
          ),
          for (final target in detail.targets)
            _DetailRow(
              label: target.label,
              value: target.price,
              color: target.isHit
                  ? TradeXColors.goldBright
                  : TradeXColors.success,
              suffix: target.isHit ? 'HIT' : null,
            ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});
  final List<TradeIdeaTimelineItem> items;
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Trade Updates',
    icon: Icons.schedule_rounded,
    child: Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: TradeXColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: TradeXColors.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.createdAt != null)
                  Text(
                    _date(item.createdAt!),
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ClosePanel extends StatelessWidget {
  const _ClosePanel({required this.close});
  final TradeIdeaClose close;
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Closed Trade',
    icon: Icons.flag_outlined,
    child: Column(
      children: [
        _DetailRow(label: 'Outcome', value: close.outcome ?? '—'),
        _DetailRow(label: 'Close price', value: close.price ?? '—'),
        if (close.note?.isNotEmpty == true)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              close.note!,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
      ],
    ),
  );
}

class _SocialBar extends StatelessWidget {
  const _SocialBar({required this.detail});
  final TradeIdeaDetail detail;
  @override
  Widget build(BuildContext context) {
    final reactions = detail.summary.reactions;
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: reactions.viewerReaction == 'LIKE'
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: '${reactions.likes}',
            selected: reactions.viewerReaction == 'LIKE',
            onTap: () => context.read<TradeIdeaDetailsCubit>().react('LIKE'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SocialButton(
            icon: Icons.thumb_down_alt_outlined,
            label: '${reactions.dislikes}',
            selected: reactions.viewerReaction == 'DISLIKE',
            onTap: () => context.read<TradeIdeaDetailsCubit>().react('DISLIKE'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SocialButton(
            icon: Icons.track_changes_rounded,
            label: '${detail.targets.length} targets',
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: selected
          ? TradeXColors.goldBright
          : TradeXColors.primaryText,
      side: BorderSide(
        color: selected ? TradeXColors.goldBright : TradeXColors.borderStrong,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.detail, required this.repository});
  final TradeIdeaDetail detail;
  final TradeIdeaRepositoryContract repository;
  @override
  Widget build(BuildContext context) {
    final idea = detail.summary;
    final symbol = const TradeIdeaTradingViewSymbolResolver().resolve(
      category: idea.category,
      symbol: idea.symbol,
      marketRegion: idea.marketRegion,
    );
    final interval = tradeIdeaTradingViewInterval(idea.timeframe);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            key: const ValueKey('open-tradingview-in-app'),
            onPressed: symbol == null
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: '/trade-ideas/tradingview',
                      ),
                      builder: (_) => TradingViewChartScreen.qualified(
                        qualifiedSymbol: symbol,
                        interval: interval,
                      ),
                    ),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: TradeXColors.goldBright,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: const Icon(Icons.candlestick_chart_rounded),
            label: const Text(
              'Open TradingView',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => _share(context, repository, detail),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: TradeXColors.borderStrong),
            ),
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [TradeXColors.surfaceRaised, TradeXColors.surface],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .62)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: TradeXColors.goldBright),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.color = TradeXColors.primaryText,
    this.suffix,
  });
  final String label;
  final String value;
  final Color color;
  final String? suffix;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 7),
          Text(
            suffix!,
            style: const TextStyle(
              color: TradeXColors.goldBright,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ChartMessage extends StatelessWidget {
  const _ChartMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: TradeXColors.backgroundSoft,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: TradeXColors.secondaryText, size: 30),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TradeXColors.secondaryText),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.lock_outline_rounded,
        size: 42,
        color: TradeXColors.secondaryText,
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TradeXColors.secondaryText),
        ),
      ),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text('Back'),
      ),
    ],
  );
}

Future<void> _share(
  BuildContext context,
  TradeIdeaRepositoryContract repository,
  TradeIdeaDetail detail,
) async {
  final channel = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: TradeXColors.surfaceRaised,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Trade Idea',
              style: TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.chat_rounded,
                color: TradeXColors.success,
              ),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.pop(context, 'WHATSAPP'),
            ),
            ListTile(
              leading: const Icon(
                Icons.send_rounded,
                color: Colors.lightBlueAccent,
              ),
              title: const Text('Telegram'),
              onTap: () => Navigator.pop(context, 'TELEGRAM'),
            ),
          ],
        ),
      ),
    ),
  );
  if (channel == null || !context.mounted) return;
  try {
    final action = await repository.shareAction(
      detail.summary.uuid,
      channel: channel,
    );
    final uri = Uri.tryParse(action.externalUrl);
    if (uri == null || uri.scheme != 'https') throw const FormatException();
    await AppPlatformRegistry.current.launchExternal(uri.toString());
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share link is temporarily unavailable.')),
      );
    }
  }
}

String _displayCategory(String value) =>
    value.isEmpty ? 'Market' : '${value[0]}${value.substring(1).toLowerCase()}';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
