part of '../learn_dashboard_widgets.dart';

class CourseThumbnail extends StatelessWidget {
  const CourseThumbnail({
    super.key,
    required this.thumbnailPath,
    required this.height,
    this.width = double.infinity,
    this.showPlay = false,
    this.durationSeconds = 0,
  });

  final String thumbnailPath;
  final double height;
  final double width;
  final bool showPlay;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final url = _thumbnailUrl(thumbnailPath);
    final fallback = const _TradingThumbnailFallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              fallback
            else
              Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 900,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .48),
                  ],
                ),
              ),
            ),
            if (showPlay)
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: learnBackground.withValues(alpha: .76),
                    shape: BoxShape.circle,
                    border: Border.all(color: learnText.withValues(alpha: .8)),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: learnText,
                    size: 29,
                  ),
                ),
              ),
            if (durationSeconds > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: learnBackground.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: learnBorder),
                  ),
                  child: Text(
                    _duration(durationSeconds),
                    style: const TextStyle(
                      color: learnText,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LearningEmptyState extends StatelessWidget {
  const LearningEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => PremiumLearningCard(
    accent: learnBorder,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined, color: learnGold, size: 36),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: learnText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: learnMuted, fontSize: 11.5),
            ),
            if (action != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    ),
  );
}

class _LearningBadge extends StatelessWidget {
  const _LearningBadge(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color),
    ),
    child: Text(
      label.toUpperCase(),
      maxLines: 1,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _CourseMeta extends StatelessWidget {
  const _CourseMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: learnMuted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: learnMuted, fontSize: 9.5)),
    ],
  );
}

class _TradingThumbnailFallback extends StatelessWidget {
  const _TradingThumbnailFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFFFFBF2),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/learning_ui/illustrations_png/featured_bull_on_rock.png',
          fit: BoxFit.contain,
        ),
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'TradeX',
              style: TextStyle(
                color: Color(0xFF292720),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String? _thumbnailUrl(String value) {
  final path = value.trim();
  if (path.isEmpty) return null;
  final parsed = Uri.tryParse(path);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) return path;
  final base = Uri.parse('${TradeXApiConfig.baseUrl}/');
  final normalized = path
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'^/+'), '');
  final publicPath = normalized.startsWith('storage/')
      ? normalized
      : 'storage/$normalized';
  return base.resolve(publicPath).toString();
}

String _duration(int seconds) {
  final safe = math.max(0, seconds);
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final remainder = safe % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}
