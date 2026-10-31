import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../market/presentation/trading_view_chart_screen.dart';
import '../data/trade_idea_repository.dart';
import '../models/trade_idea_models.dart';
import '../services/tradingview_symbol_resolver.dart';
import 'bloc/trade_idea_details_cubit.dart';

class TradeIdeaDetailsScreen extends StatelessWidget {
  const TradeIdeaDetailsScreen({
    super.key,
    required this.repository,
    required this.uuid,
  });

  final TradeIdeaDataSource repository;
  final String uuid;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TradeIdeaDetailsCubit(repository: repository, uuid: uuid)..load(),
    child: _TradeIdeaDetailsView(repository: repository),
  );
}

class _TradeIdeaDetailsView extends StatelessWidget {
  const _TradeIdeaDetailsView({required this.repository});
  final TradeIdeaDataSource repository;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: SafeArea(
      child: BlocConsumer<TradeIdeaDetailsCubit, TradeIdeaDetailsState>(
        listenWhen: (previous, current) =>
            previous.reactionMessage != current.reactionMessage &&
            current.reactionMessage != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.reactionMessage!))),
        builder: (context, state) {
          if (state.status == TradeIdeaLoadStatus.loading ||
              state.status == TradeIdeaLoadStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            );
          }
          if (state.status == TradeIdeaLoadStatus.failure ||
              state.detail == null) {
            return _LoadFailure(
              message: state.message ?? 'Trade Idea is unavailable.',
              onRetry: context.read<TradeIdeaDetailsCubit>().load,
            );
          }
          final detail = state.detail!;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(detail: detail, repository: repository),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
                sliver: SliverList.list(
                  children: [
                    _ChartPanel(detail: detail, state: state),
                    const SizedBox(height: 12),
                    _TradeSetup(detail: detail),
                    if (detail.analysis.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Panel(
                        title: 'Analysis',
                        icon: Icons.article_outlined,
                        child: Text(
                          detail.analysis,
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (detail.timeline.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Timeline(items: detail.timeline),
                    ],
                    if (detail.close.outcome != null) ...[
                      const SizedBox(height: 12),
                      _ClosePanel(close: detail.close),
                    ],
                    const SizedBox(height: 12),
                    _SocialBar(detail: detail),
                    const SizedBox(height: 12),
                    _PrimaryActions(detail: detail, repository: repository),
                    const SizedBox(height: 16),
                    Text(
                      detail.riskNotice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.repository});
  final TradeIdeaDetail detail;
  final TradeIdeaDataSource repository;
  @override
  Widget build(BuildContext context) {
    final idea = detail.summary;
    final buy = idea.direction == 'BUY';
    final accent = buy ? TradeXColors.success : TradeXColors.error;
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
              const Expanded(
                child: Text(
                  'Trade Idea Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TradeXColors.primaryText,
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
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TradeXColors.goldBright, TradeXColors.goldDeep],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  idea.symbol.substring(
                    0,
                    idea.symbol.length.clamp(0, 3).toInt(),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_displayCategory(idea.category)}  •  ${idea.timeframe}',
                      style: const TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      idea.instrumentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: TradeXColors.secondaryText),
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
                  borderRadius: BorderRadius.circular(12),
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

class _ChartPanel extends StatefulWidget {
  const _ChartPanel({required this.detail, required this.state});
  final TradeIdeaDetail detail;
  final TradeIdeaDetailsState state;
  @override
  State<_ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<_ChartPanel> {
  bool _liveCreated = false;
  @override
  void didUpdateWidget(covariant _ChartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.chartTab == TradeIdeaChartTab.live) _liveCreated = true;
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.detail.summary;
    final symbol = const TradeIdeaTradingViewSymbolResolver().resolve(
      category: idea.category,
      symbol: idea.symbol,
      marketRegion: idea.marketRegion,
    );
    final interval = tradeIdeaTradingViewInterval(idea.timeframe);
    return Container(
      decoration: BoxDecoration(
        color: TradeXColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TradeXColors.borderStrong),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'My Analysis',
                    selected:
                        widget.state.chartTab == TradeIdeaChartTab.analysis,
                    onTap: () => context
                        .read<TradeIdeaDetailsCubit>()
                        .selectChartTab(TradeIdeaChartTab.analysis),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: 'Live Chart',
                    selected: widget.state.chartTab == TradeIdeaChartTab.live,
                    onTap: () {
                      setState(() => _liveCreated = true);
                      context.read<TradeIdeaDetailsCubit>().selectChartTab(
                        TradeIdeaChartTab.live,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: IndexedStack(
              index: widget.state.chartTab == TradeIdeaChartTab.analysis
                  ? 0
                  : 1,
              children: [
                _AnalysisChart(state: widget.state),
                symbol == null
                    ? const _ChartMessage(
                        icon: Icons.info_outline_rounded,
                        message: 'Live chart is unavailable because this market symbol has no verified TradingView mapping.',
                      )
                    : _liveCreated
                    ? Stack(
                        children: [
                          TradingViewChartView(
                            qualifiedSymbol: symbol,
                            interval: interval,
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: IconButton.filledTonal(
                              tooltip: 'Full screen',
                              onPressed: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TradingViewChartScreen.qualified(
                                        qualifiedSymbol: symbol,
                                        interval: interval,
                                      ),
                                ),
                              ),
                              icon: const Icon(Icons.fullscreen_rounded),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisChart extends StatelessWidget {
  const _AnalysisChart({required this.state});
  final TradeIdeaDetailsState state;
  @override
  Widget build(BuildContext context) => switch (state.analysisStatus) {
    TradeIdeaAnalysisStatus.loading ||
    TradeIdeaAnalysisStatus.idle => const Center(
      child: CircularProgressIndicator(color: TradeXColors.goldBright),
    ),
    TradeIdeaAnalysisStatus.empty => const _ChartMessage(
      icon: Icons.image_not_supported_outlined,
      message: 'Admin analysis chart has not been uploaded.',
    ),
    TradeIdeaAnalysisStatus.failure => _ChartMessage(
      icon: Icons.cloud_off_rounded,
      message: state.analysisMessage ?? 'Analysis chart is unavailable.',
      onRetry: context.read<TradeIdeaDetailsCubit>().loadAnalysis,
    ),
    TradeIdeaAnalysisStatus.loaded => _ZoomableAnalysis(
      bytes: state.analysisBytes!,
    ),
  };
}

class _ZoomableAnalysis extends StatefulWidget {
  const _ZoomableAnalysis({required this.bytes});
  final Uint8List bytes;
  @override
  State<_ZoomableAnalysis> createState() => _ZoomableAnalysisState();
}

class _ZoomableAnalysisState extends State<_ZoomableAnalysis> {
  final _controller = TransformationController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 5,
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
      Positioned(
        right: 6,
        bottom: 6,
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Reset zoom',
              onPressed: () => _controller.value = Matrix4.identity(),
              icon: const Icon(Icons.center_focus_strong_rounded),
            ),
            const SizedBox(width: 5),
            IconButton.filledTonal(
              tooltip: 'Full screen',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => _AnalysisFullScreen(bytes: widget.bytes),
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded),
            ),
          ],
        ),
      ),
    ],
  );
}

class _AnalysisFullScreen extends StatelessWidget {
  const _AnalysisFullScreen({required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: .5,
              maxScale: 6,
              child: Center(child: Image.memory(bytes)),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? TradeXColors.goldBright : TradeXColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? TradeXColors.goldBright : TradeXColors.borderStrong,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? Colors.black : TradeXColors.primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

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
  final TradeIdeaDataSource repository;
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
  TradeIdeaDataSource repository,
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
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
