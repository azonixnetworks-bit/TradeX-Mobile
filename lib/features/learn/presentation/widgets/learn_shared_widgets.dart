part of '../learn_module.dart';

class _LearnScaffold extends StatelessWidget {
  const _LearnScaffold({
    required this.title,
    required this.child,
    this.actions,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset(
              'assets/branding/trade_x_final_logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -22,
              child: IgnorePointer(
                child: Opacity(
                  opacity: context.isDarkMode ? .1 : .36,
                  child: Image.asset(
                    'assets/learning_ui/decorations_png/delicate_golden_candlestick_trend.png',
                    width: 175,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -16,
              child: IgnorePointer(
                child: Opacity(
                  opacity: context.isDarkMode ? .06 : .5,
                  child: Image.asset(
                    'assets/learning_ui/decorations_png/soft_ivory_wave_footer.png',
                    height: 120,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureBody extends StatelessWidget {
  const _FutureBody({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
  });
  final Future<JsonMap> future;
  final Widget Function(JsonMap) builder;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => BlocFutureBuilder<JsonMap>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: _gold));
      }
      if (snapshot.hasError) {
        return _ErrorState(
          onRetry: onRetry,
          message: snapshot.error.toString(),
        );
      }
      return builder(snapshot.data ?? const {});
    },
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _gold, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: TradeXRadii.card,
        border: Border.all(color: palette.border),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: child,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ],
    ),
  );
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.item, this.onTap});
  final JsonMap item;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final lesson = LearnRepository.map(item['lesson']);
    final module = LearnRepository.map(item['module']);
    final course = LearnRepository.map(item['course']);
    final title = LearnRepository.text(
      lesson['title'],
      LearnRepository.text(item['lesson_title'], 'Start learning'),
    );
    final percent = LearnRepository.number(item['progress_percent']);
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
    return _PremiumCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (thumbnail.isNotEmpty) ...[
              CourseThumbnail(
                thumbnailPath: thumbnail,
                width: 96,
                height: 84,
                showPlay: true,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${LearnRepository.text(course['title'], LearnRepository.text(item['course_title']))} • ${LearnRepository.text(module['title'], LearnRepository.text(item['module_title']))}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percent.clamp(0, 100) / 100,
                    minHeight: 6,
                    color: _gold,
                    backgroundColor: TradeXColors.border,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _gold),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, this.onTap});
  final JsonMap course;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final locked = LearnRepository.flag(course['is_locked']);
    final progress = LearnRepository.map(course['progress']);
    final courseUuid = LearnRepository.text(course['uuid']);
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    return _PremiumCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CourseThumbnail(
              key: ValueKey('course-thumbnail-$courseUuid'),
              thumbnailPath: thumbnail,
              width: 112,
              height: 96,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBadge(
                    LearnRepository.text(course['access_level'], 'FREE'),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    LearnRepository.text(course['title'], 'Course'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${LearnRepository.number(course['lesson_count'] ?? progress['total_lessons'])} lessons  •  ${LearnRepository.number(progress['percent'])}%',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: _gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course, required this.modules});
  final JsonMap course;
  final List<dynamic> modules;
  @override
  Widget build(BuildContext context) {
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    final summary = LearnRepository.text(course['short_description']);
    final description = LearnRepository.text(course['description'], summary);
    final progress = LearnRepository.map(course['progress']);
    final lessonCount = LearnRepository.number(progress['total_lessons']);
    final percent = LearnRepository.number(progress['percent']).clamp(0, 100);
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail.isNotEmpty)
            CourseThumbnail(
              key: ValueKey(
                'course-hero-thumbnail-${LearnRepository.text(course['uuid'])}',
              ),
              thumbnailPath: thumbnail,
              height: 185,
            )
          else
            Container(
              height: 185,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.palette.goldSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/learning_ui/illustrations_png/course_details_full_hero.png',
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 14),
          _StatusBadge(LearnRepository.text(course['access_level'], 'COURSE')),
          const SizedBox(height: 8),
          Text(
            LearnRepository.text(course['title'], 'TradeX Course'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.palette.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (summary.isNotEmpty || description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ExpandableCourseDescription(
              body: summary.isEmpty ? description : summary,
              expandedBody: description,
            ),
          ],
          if (modules.isNotEmpty || lessonCount > 0 || progress.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (modules.isNotEmpty)
                  Expanded(
                    child: _CourseStat(
                      icon: Icons.layers_outlined,
                      label: '${modules.length} Modules',
                    ),
                  ),
                if (modules.isNotEmpty && lessonCount > 0)
                  const SizedBox(width: 8),
                if (lessonCount > 0)
                  Expanded(
                    child: _CourseStat(
                      icon: Icons.play_circle_outline_rounded,
                      label: '$lessonCount Lessons',
                    ),
                  ),
                if ((modules.isNotEmpty || lessonCount > 0) &&
                    progress.isNotEmpty)
                  const SizedBox(width: 8),
                if (progress.isNotEmpty)
                  Expanded(
                    child: _CourseStat(
                      icon: Icons.track_changes_rounded,
                      label: '$percent% Complete',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableCourseDescription extends StatefulWidget {
  const _ExpandableCourseDescription({
    required this.body,
    required this.expandedBody,
  });

  final String body;
  final String expandedBody;

  @override
  State<_ExpandableCourseDescription> createState() =>
      _ExpandableCourseDescriptionState();
}

class _ExpandableCourseDescriptionState
    extends State<_ExpandableCourseDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.palette.primaryText, height: 1.55);
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsedText = widget.body;
        final expandedText = widget.expandedBody.isEmpty
            ? widget.body
            : widget.expandedBody;
        final painter = TextPainter(
          text: TextSpan(text: collapsedText, style: style),
          maxLines: 4,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand =
            painter.didExceedMaxLines || expandedText != collapsedText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Text(
                _expanded ? expandedText : collapsedText,
                key: const ValueKey('course-description-text'),
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (canExpand || _expanded) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                key: const ValueKey('course-description-toggle'),
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.goldText,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(_expanded ? 'Show less' : 'Read more'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CourseStat extends StatelessWidget {
  const _CourseStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(
      color: context.palette.surfaceRaised,
      borderRadius: TradeXRadii.control,
      border: Border.all(color: context.palette.borderStrong),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: context.palette.goldText),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.palette.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CourseContinueCard extends StatelessWidget {
  const _CourseContinueCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  final JsonMap lesson;
  final JsonMap progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = LearnRepository.number(progress['percent']).clamp(0, 100);
    return _PremiumCard(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: context.palette.goldSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              color: context.palette.goldText,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Learning',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.palette.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  LearnRepository.text(lesson['title'], 'Current lesson'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.palette.secondaryText),
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 6,
                  color: context.palette.gold,
                  backgroundColor: context.palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            key: const ValueKey('course-continue-learning'),
            onPressed: onTap,
            tooltip: 'Continue learning',
            style: IconButton.styleFrom(
              backgroundColor: context.palette.gold,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class _CourseModulePreviewCard extends StatelessWidget {
  const _CourseModulePreviewCard({
    required this.index,
    required this.module,
    required this.onTap,
  });

  final int index;
  final JsonMap module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = LearnRepository.number(module['lesson_count']);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TradeXRadii.control,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: TradeXRadii.control,
            border: Border.all(color: context.palette.borderStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: context.palette.goldText,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(index + 1).toString().padLeft(2, '0')}. ${LearnRepository.text(module['title'], 'Module')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.palette.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'No lessons published yet'
                          : '$count ${count == 1 ? 'Lesson' : 'Lessons'}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.palette.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.palette.goldText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurriculumSummaryCard extends StatelessWidget {
  const _CurriculumSummaryCard({required this.course, required this.modules});

  final JsonMap course;
  final List<dynamic> modules;

  @override
  Widget build(BuildContext context) {
    final progress = LearnRepository.map(course['progress']);
    final lessonCount = LearnRepository.number(progress['total_lessons']);
    final percent = LearnRepository.number(progress['percent']).clamp(0, 100);
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail.isNotEmpty) ...[
            CourseThumbnail(thumbnailPath: thumbnail, height: 128),
            const SizedBox(height: 12),
          ],
          Text(
            LearnRepository.text(course['title'], 'TradeX Course'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.palette.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          finalSummary(course, context),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CourseStat(
                  icon: Icons.track_changes_rounded,
                  label: '$percent% Complete',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CourseStat(
                  icon: Icons.layers_outlined,
                  label: '${modules.length} Modules',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CourseStat(
                  icon: Icons.play_circle_outline_rounded,
                  label: '$lessonCount Lessons',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget finalSummary(JsonMap value, BuildContext context) {
    final summary = LearnRepository.text(value['short_description']);
    if (summary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: context.palette.secondaryText),
      ),
    );
  }
}

class _CurriculumModuleCard extends StatelessWidget {
  const _CurriculumModuleCard({
    required this.index,
    required this.module,
    required this.expanded,
    required this.onToggle,
    required this.onLessonTap,
  });

  final int index;
  final JsonMap module;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<JsonMap> onLessonTap;

  @override
  Widget build(BuildContext context) {
    final lessons = LearnRepository.list(module['lessons'])
        .map(LearnRepository.map)
        .toList(growable: false);
    final completed = lessons.where((lesson) {
      final progress = LearnRepository.map(lesson['progress']);
      return LearnRepository.text(progress['status']).toUpperCase() ==
          'COMPLETED';
    }).length;
    final percent = lessons.isEmpty
        ? 0
        : ((completed / lessons.length) * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: TradeXRadii.card,
        border: Border.all(color: context.palette.gold.withValues(alpha: .62)),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: context.palette,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            key: ValueKey(
              'curriculum-module-${LearnRepository.text(module['uuid'])}',
            ),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.palette.goldSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.layers_outlined,
                      color: context.palette.goldText,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(index + 1).toString().padLeft(2, '0')}. ${LearnRepository.text(module['title'], 'Module')}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.palette.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lessons.isEmpty
                              ? 'No lessons published yet'
                              : '${lessons.length} ${lessons.length == 1 ? 'Lesson' : 'Lessons'} · $percent% Complete',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.palette.secondaryText),
                        ),
                        if (lessons.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 5,
                            color: context.palette.gold,
                            backgroundColor: context.palette.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.palette.primaryText,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: expanded && lessons.isNotEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: context.palette.surfaceRaised,
                      border: Border(
                        top: BorderSide(color: context.palette.border),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (
                          var lessonIndex = 0;
                          lessonIndex < lessons.length;
                          lessonIndex++
                        ) ...[
                          _CurriculumLessonRow(
                            index: lessonIndex,
                            lesson: lessons[lessonIndex],
                            onTap: () => onLessonTap(lessons[lessonIndex]),
                          ),
                          if (lessonIndex != lessons.length - 1)
                            Divider(
                              height: 1,
                              indent: 54,
                              color: context.palette.border,
                            ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CurriculumLessonRow extends StatelessWidget {
  const _CurriculumLessonRow({
    required this.index,
    required this.lesson,
    required this.onTap,
  });

  final int index;
  final JsonMap lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = LearnRepository.map(lesson['progress']);
    final status = LearnRepository.text(
      progress['status'],
      'NOT_STARTED',
    ).toUpperCase();
    final completed = status == 'COMPLETED';
    final inProgress = status == 'IN_PROGRESS';
    final locked = LearnRepository.flag(lesson['is_locked']);
    return InkWell(
      key: ValueKey(
        'curriculum-lesson-${LearnRepository.text(lesson['uuid'])}',
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Icon(
              locked
                  ? Icons.lock_outline_rounded
                  : completed
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_outline_rounded,
              color: completed
                  ? context.palette.success
                  : context.palette.goldText,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${index + 1}. ${LearnRepository.text(lesson['title'], 'Lesson')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.palette.primaryText,
                  fontWeight: inProgress || completed
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            if (completed)
              Text(
                'Completed',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.palette.success,
                  fontWeight: FontWeight.w800,
                ),
              )
            else if (inProgress)
              Text(
                'Continue',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.palette.goldText,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});
  final JsonMap lesson;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final locked = LearnRepository.flag(lesson['is_locked']);
    final progress = LearnRepository.map(lesson['progress']);
    final thumbnail = _thumbnailValue(lesson);
    return _PremiumCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: thumbnail.isNotEmpty
            ? CourseThumbnail(
                thumbnailPath: thumbnail,
                width: 72,
                height: 58,
                showPlay: !locked,
              )
            : Icon(
                locked
                    ? Icons.lock
                    : LearnRepository.text(progress['status']) == 'COMPLETED'
                    ? Icons.check_circle
                    : Icons.play_circle_outline,
                color: locked
                    ? _gold
                    : LearnRepository.text(progress['status']) == 'COMPLETED'
                    ? TradeXColors.success
                    : Theme.of(context).colorScheme.onSurface,
              ),
        title: Text(LearnRepository.text(lesson['title'], 'Lesson')),
        subtitle: Text(
          LearnRepository.flag(lesson['is_preview'])
              ? 'FREE preview'
              : 'Protected lesson',
        ),
        onTap: onTap,
      ),
    );
  }
}

String _thumbnailValue(JsonMap item) {
  final url = LearnRepository.text(item['thumbnail_url']);
  return url.isNotEmpty ? url : LearnRepository.text(item['thumbnail_path']);
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.completed,
    required this.total,
    required this.percent,
  });
  final int completed, total, percent;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Learning Progress',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: percent.clamp(0, 100) / 100,
          minHeight: 8,
          color: _gold,
          backgroundColor: TradeXColors.border,
        ),
        const SizedBox(height: 8),
        Text(
          '$percent% • $completed of $total lessons completed',
          style: const TextStyle(color: TradeXColors.secondaryText),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: _gold),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _gold,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: TradeXColors.secondaryText),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _gold, size: 42),
          const SizedBox(height: 10),
          const Text('Learning is unavailable right now.'),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 12,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
