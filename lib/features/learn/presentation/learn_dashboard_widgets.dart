import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/tradex_api_config.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/learn_repository.dart';

const learnBackground = TradeXColors.background;
const learnCard = TradeXColors.surface;
const learnCardRaised = TradeXColors.surfaceRaised;
const learnBorder = TradeXColors.goldSoft;
const learnGold = TradeXColors.goldBright;
const learnGreen = TradeXColors.goldBright;
const learnBlue = TradeXColors.goldBright;
const learnPurple = TradeXColors.goldBright;
const learnCyan = TradeXColors.goldBright;
const learnText = TradeXColors.primaryText;
const learnMuted = TradeXColors.secondaryText;

class LearnDashboardHeader extends StatelessWidget {
  const LearnDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Learn'),
            TextSpan(
              text: '.',
              style: TextStyle(color: learnGold),
            ),
          ],
        ),
        style: TextStyle(
          color: learnText,
          fontSize: 30,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Build skill, discipline and consistency.',
        style: TextStyle(
          color: learnMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class LearningSectionHeader extends StatelessWidget {
  const LearningSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
    this.accent = learnGold,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .13),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .16), blurRadius: 14),
          ],
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: learnText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (action != null)
        TextButton.icon(
          key: ValueKey('learn-section-$action'),
          onPressed: onAction,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          label: Text(action!),
          style: TextButton.styleFrom(
            foregroundColor: learnGold,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
    ],
  );
}

class PremiumLearningCard extends StatelessWidget {
  const PremiumLearningCard({
    super.key,
    required this.child,
    this.accent = learnBorder,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TradeXColors.surfaceRaised,
              TradeXColors.surface,
              TradeXColors.backgroundSoft,
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: accent.withValues(alpha: .78)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .09),
              blurRadius: 20,
              spreadRadius: -7,
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class LessonProgressIndicator extends StatelessWidget {
  const LessonProgressIndicator({
    super.key,
    required this.percent,
    this.showLabel = true,
  });

  final int percent;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final safe = percent.clamp(0, 100);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: safe / 100,
              minHeight: 8,
              color: learnGold,
              backgroundColor: learnBorder.withValues(alpha: .48),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 11),
          Text(
            '$safe%',
            style: const TextStyle(
              color: learnText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.item,
    required this.onContinue,
    this.loading = false,
    this.starting = false,
  });

  final JsonMap item;
  final VoidCallback? onContinue;
  final bool loading;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final course = LearnRepository.map(item['course']);
    final module = LearnRepository.map(item['module']);
    final lesson = LearnRepository.map(item['lesson']);
    final percent = LearnRepository.number(item['progress_percent'])
        .clamp(0, 100);
    final title = LearnRepository.text(
      lesson['title'],
      LearnRepository.text(item['lesson_title'], 'Start learning'),
    );
    final courseTitle = LearnRepository.text(
      course['title'],
      LearnRepository.text(item['course_title']),
    );
    final moduleTitle = LearnRepository.text(
      module['title'],
      LearnRepository.text(item['module_title']),
    );
    final completed =
        percent >= 100 ||
        LearnRepository.text(item['status']).toUpperCase() == 'COMPLETED';
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    return PremiumLearningCard(
      key: const ValueKey('continue-learning-card'),
      accent: learnGold,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 610;
          final image = CourseThumbnail(
            thumbnailPath: thumbnail,
            height: horizontal ? 150 : 154,
            width: horizontal ? 245 : double.infinity,
            showPlay: true,
          );
          final details = Padding(
            padding: EdgeInsets.only(
              left: horizontal ? 18 : 2,
              top: horizontal ? 2 : 14,
              right: 2,
              bottom: 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LearningBadge(
                  completed
                      ? 'COMPLETED'
                      : starting
                      ? 'START HERE'
                      : 'IN PROGRESS',
                  color: completed ? learnGreen : learnGold,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: learnText,
                    fontSize: 18,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (courseTitle.isNotEmpty || moduleTitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      courseTitle,
                      moduleTitle,
                    ].where((value) => value.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: learnMuted, fontSize: 11.5),
                  ),
                ],
                const SizedBox(height: 14),
                LessonProgressIndicator(percent: percent),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const ValueKey('continue-learning-button'),
                    onPressed: loading ? null : onContinue,
                    iconAlignment: IconAlignment.end,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    label: Text(
                      loading
                          ? 'Loading…'
                          : completed
                          ? 'Replay'
                          : starting
                          ? 'Start Learning'
                          : 'Continue',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: learnGold,
                      foregroundColor: learnBackground,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          );
          if (horizontal) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                Expanded(child: details),
              ],
            );
          }
          return Column(children: [image, details]);
        },
      ),
    );
  }
}

class LearningShortcutData {
  const LearningShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
}

class LearningShortcutCard extends StatelessWidget {
  const LearningShortcutCard({super.key, required this.data});

  final LearningShortcutData data;

  @override
  Widget build(BuildContext context) => PremiumLearningCard(
    key: ValueKey('learn-shortcut-${data.title.toLowerCase()}'),
    accent: data.accent,
    onTap: data.onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: .2),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(data.icon, color: data.accent, size: 25),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: learnText,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            data.title,
            style: const TextStyle(
              color: learnText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: learnMuted, fontSize: 10.5),
          ),
        ],
      ),
    ),
  );
}

class LearningShortcutGrid extends StatelessWidget {
  const LearningShortcutGrid({super.key, required this.items});

  final List<LearningShortcutData> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 3 : 2;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: LearningShortcutCard(data: item),
            ),
        ],
      );
    },
  );
}

class FreeLessonCard extends StatelessWidget {
  const FreeLessonCard({
    super.key,
    required this.item,
    required this.bookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  final JsonMap item;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final course = LearnRepository.map(item['course']);
    final lesson = LearnRepository.map(item['lesson']);
    final title = LearnRepository.text(
      lesson['title'],
      LearnRepository.text(item['lesson_title'], 'TradeX lesson'),
    );
    final thumbnail = LearnRepository.text(
      lesson['thumbnail_url'],
      LearnRepository.text(
        lesson['thumbnail_path'],
        LearnRepository.text(
          course['thumbnail_url'],
          LearnRepository.text(course['thumbnail_path']),
        ),
      ),
    );
    final duration = LearnRepository.number(
      item['duration_seconds'] ?? lesson['duration_seconds'],
    );
    final level = LearnRepository.text(
      lesson['level'],
      LearnRepository.text(item['level']),
    );
    final uuid = LearnRepository.text(
      lesson['uuid'],
      LearnRepository.text(item['lesson_uuid']),
    );
    return SizedBox(
      key: ValueKey('free-lesson-$uuid'),
      width: 238,
      child: PremiumLearningCard(
        accent: learnCyan,
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseThumbnail(
              thumbnailPath: thumbnail,
              height: 118,
              durationSeconds: duration,
              showPlay: true,
            ),
            const SizedBox(height: 11),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: learnText,
                fontSize: 14,
                height: 1.18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _LearningBadge(
                  level.isEmpty ? 'FREE' : level,
                  color: level.toLowerCase().contains('inter')
                      ? learnBlue
                      : learnGreen,
                ),
                const Spacer(),
                IconButton(
                  key: ValueKey('bookmark-$uuid'),
                  tooltip: bookmarked ? 'Remove bookmark' : 'Save lesson',
                  onPressed: onBookmark,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: bookmarked ? learnGold : learnText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedCourseCard extends StatelessWidget {
  const FeaturedCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.width,
  });

  final JsonMap course;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final progress = LearnRepository.map(course['progress']);
    final title = LearnRepository.text(course['title'], 'TradeX course');
    final description = LearnRepository.text(course['short_description']);
    final access = LearnRepository.text(course['access_level'], 'FREE');
    final lessonCount = LearnRepository.number(
      progress['total_lessons'] ?? course['lesson_count'],
    );
    final duration = LearnRepository.number(course['duration_seconds']);
    final level = LearnRepository.text(course['level']);
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    return SizedBox(
      key: ValueKey('featured-course-${LearnRepository.text(course['uuid'])}'),
      width: width,
      child: PremiumLearningCard(
        accent: learnGold,
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseThumbnail(
              thumbnailPath: thumbnail,
              height: 120,
              durationSeconds: duration,
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                _LearningBadge(
                  access,
                  color: access.toUpperCase() == 'PREMIUM'
                      ? learnGold
                      : learnGreen,
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: learnGold,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: learnText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: learnMuted,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
            const Spacer(),
            Wrap(
              spacing: 13,
              runSpacing: 5,
              children: [
                if (lessonCount > 0)
                  _CourseMeta(
                    icon: Icons.play_circle_outline_rounded,
                    label: '$lessonCount lessons',
                  ),
                if (duration > 0)
                  _CourseMeta(
                    icon: Icons.schedule_rounded,
                    label: _duration(duration),
                  ),
                if (level.isNotEmpty)
                  _CourseMeta(icon: Icons.bar_chart_rounded, label: level),
              ],
            ),
            const SizedBox(height: 8),
            LessonProgressIndicator(
              percent: LearnRepository.number(progress['percent']),
              showLabel: true,
            ),
          ],
        ),
      ),
    );
  }
}

class LearningProgressCard extends StatelessWidget {
  const LearningProgressCard({
    super.key,
    required this.completed,
    required this.total,
    required this.percent,
    required this.onTap,
  });

  final int completed;
  final int total;
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safeTotal = math.max(0, total);
    final safeCompleted = safeTotal == 0
        ? math.max(0, completed)
        : completed.clamp(0, safeTotal);
    final safePercent = safeTotal == 0 ? 0 : percent.clamp(0, 100);
    return PremiumLearningCard(
      key: const ValueKey('overall-learning-progress'),
      accent: learnGold,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: learnGold.withValues(alpha: .13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: learnGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Overall Learning Progress',
                        style: TextStyle(
                          color: learnText,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '$safePercent%',
                      key: const ValueKey('learning-progress-percent'),
                      style: const TextStyle(
                        color: learnGold,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LessonProgressIndicator(percent: safePercent, showLabel: false),
                const SizedBox(height: 9),
                Text(
                  safeTotal == 0
                      ? 'No accessible lessons are available yet.'
                      : '$safeCompleted of $safeTotal lessons completed',
                  style: const TextStyle(color: learnMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) => CustomPaint(
    painter: _TradingThumbnailPainter(),
    child: const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'TradeX',
          style: TextStyle(
            color: learnText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ),
  );
}

class _TradingThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [TradeXColors.surfaceRaised, TradeXColors.background],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final grid = Paint()
      ..color = learnBorder.withValues(alpha: .24)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final random = math.Random(19);
    var price = size.height * .62;
    final candleWidth = size.width / 17;
    for (var i = 0; i < 14; i++) {
      final delta = (random.nextDouble() - .46) * size.height * .15;
      final next = (price + delta).clamp(size.height * .18, size.height * .83);
      final x = size.width * .08 + i * candleWidth;
      final rising = next < price;
      final color = rising ? learnGold : TradeXColors.goldSoft;
      final candle = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(x, math.min(price, next) - size.height * .07),
        Offset(x, math.max(price, next) + size.height * .07),
        candle,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          x - candleWidth * .22,
          math.min(price, next),
          x + candleWidth * .22,
          math.max(price, next) + 2,
        ),
        candle,
      );
      price = next;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
