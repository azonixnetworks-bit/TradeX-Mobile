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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(title),
      actions: actions,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: child,
      ),
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: child,
  );
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
    return _PremiumCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              '${LearnRepository.text(course['title'], LearnRepository.text(item['course_title']))} • ${LearnRepository.text(module['title'], LearnRepository.text(item['module_title']))}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              color: _gold,
              backgroundColor: TradeXColors.border,
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseThumbnail(
              key: ValueKey('course-thumbnail-$courseUuid'),
              thumbnailPath: thumbnail,
              height: 150,
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: Text(
                    LearnRepository.text(course['title'], 'Course'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(locked ? Icons.lock : Icons.arrow_forward, color: _gold),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              LearnRepository.text(course['short_description']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: TradeXColors.secondaryText),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusBadge(
                  LearnRepository.text(course['access_level'], 'FREE'),
                ),
                const Spacer(),
                Text('${LearnRepository.number(progress['percent'])}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});
  final JsonMap course;
  @override
  Widget build(BuildContext context) {
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    final body = LearnRepository.text(
      course['description'],
      LearnRepository.text(course['short_description']),
    );
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CourseThumbnail(
            key: ValueKey(
              'course-hero-thumbnail-${LearnRepository.text(course['uuid'])}',
            ),
            thumbnailPath: thumbnail,
            height: 185,
          ),
          const SizedBox(height: 14),
          Text(
            LearnRepository.text(course['title'], 'TradeX Course'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
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
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});
  final JsonMap module;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final thumbnail = _thumbnailValue(module);
    return _PremiumCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: thumbnail.isEmpty
            ? const Icon(Icons.view_module_rounded, color: _gold, size: 32)
            : CourseThumbnail(thumbnailPath: thumbnail, width: 72, height: 58),
        title: Text(
          LearnRepository.text(module['title'], 'Module'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${LearnRepository.number(module['lesson_count'])} lessons',
        ),
        trailing: const Icon(Icons.chevron_right, color: _gold),
        onTap: onTap,
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
