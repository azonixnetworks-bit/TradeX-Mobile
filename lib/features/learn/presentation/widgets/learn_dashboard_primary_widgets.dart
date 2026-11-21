part of '../learn_dashboard_widgets.dart';

class LearnDashboardHeader extends StatelessWidget {
  const LearnDashboardHeader({super.key, this.onNotifications});

  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Learn'),
            TextSpan(
              text: '.',
              style: TextStyle(color: context.palette.gold),
            ),
          ],
        ),
        style: TextStyle(
          color: context.palette.primaryText,
          fontSize: 30,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Your Trading Learning Hub',
        style: TextStyle(
          color: context.palette.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class UnlockPremiumCard extends StatelessWidget {
  const UnlockPremiumCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const ValueKey('learn-unlock-premium-card'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF33270C), Color(0xFF171A15)],
          ),
          border: Border.all(color: learnGold.withValues(alpha: .55)),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: learnGold),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unlock Premium',
                style: TextStyle(
                  color: learnText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: learnGold),
          ],
        ),
      ),
    ),
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
          style: TextStyle(
            color: context.palette.primaryText,
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cardRadius = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: cardRadius,
            border: Border.all(color: palette.gold.withValues(alpha: .72)),
            boxShadow: TradeXElevation.surface(
              brightness: Theme.of(context).brightness,
              palette: palette,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
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
            style: TextStyle(
              color: context.palette.primaryText,
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
      onTap: loading ? null : onContinue,
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
                  style: TextStyle(
                    color: context.palette.primaryText,
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
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11.5,
                    ),
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
              Icon(
                Icons.chevron_right_rounded,
                color: context.palette.primaryText,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            data.title,
            style: TextStyle(
              color: context.palette.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 10.5,
            ),
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
