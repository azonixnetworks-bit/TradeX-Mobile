part of '../trade_idea_details_screen.dart';

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
    final palette = context.palette;
    final idea = widget.detail.summary;
    final symbol = const TradeIdeaTradingViewSymbolResolver().resolve(
      category: idea.category,
      symbol: idea.symbol,
      marketRegion: idea.marketRegion,
    );
    final interval = tradeIdeaTradingViewInterval(idea.timeframe);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: TradeXRadii.card,
        border: Border.all(color: palette.borderStrong),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
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
    TradeIdeaAnalysisStatus.loading || TradeIdeaAnalysisStatus.idle => Center(
      child: CircularProgressIndicator(color: context.palette.gold),
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
    borderRadius: TradeXRadii.control,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? context.palette.gold : context.palette.surfaceRaised,
        borderRadius: TradeXRadii.control,
        border: Border.all(
          color: selected ? context.palette.gold : context.palette.borderStrong,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected
              ? context.palette.primaryButtonText
              : context.palette.primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
