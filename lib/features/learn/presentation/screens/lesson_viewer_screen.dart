part of '../learn_module.dart';

class UniversalLessonViewerScreen extends StatefulWidget {
  const UniversalLessonViewerScreen({
    super.key,
    required this.repository,
    required this.lessonUuid,
  });
  final LearnRepository repository;
  final String lessonUuid;
  @override
  State<UniversalLessonViewerScreen> createState() =>
      _UniversalLessonViewerScreenState();
}

class _UniversalLessonViewerScreenState
    extends State<UniversalLessonViewerScreen> {
  bool bookmarked = false;
  bool _completing = false;
  bool _completed = false;
  JsonMap _nextLesson = const <String, dynamic>{};
  late Future<JsonMap> future = widget.repository.lesson(widget.lessonUuid);

  @override
  void initState() {
    super.initState();
    _markLessonStarted();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ActivityTrackingScope.maybeOf(context)
          ?.track('learning', 'lesson_viewed', subjectId: widget.lessonUuid);
    });
  }

  Future<void> _markLessonStarted() async {
    try {
      await widget.repository.updateProgress(
        widget.lessonUuid,
        status: 'IN_PROGRESS',
      );
    } catch (_) {
      // Progress sync must never prevent the protected lesson content from
      // opening. The viewer's read request remains the source of truth.
    }
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Lesson Viewer',
    actions: [
      IconButton(
        tooltip: 'Save lesson',
        icon: Icon(
          bookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: _gold,
        ),
        onPressed: () async {
          setState(() => bookmarked = !bookmarked);
          await widget.repository.setBookmark(widget.lessonUuid, bookmarked);
        },
      ),
    ],
    child: _FutureBody(
      future: future,
      builder: (data) {
        final lesson = LearnRepository.map(data['lesson']);
        final videos = LearnRepository.list(data['videos']);
        final progress = LearnRepository.map(data['progress']);
        final completed =
            _completed ||
            LearnRepository.text(progress['status']).toUpperCase() ==
                'COMPLETED';
        final course = LearnRepository.map(data['course'] ?? lesson['course']);
        final module = LearnRepository.map(data['module'] ?? lesson['module']);
        final firstVideo = videos.isEmpty
            ? <String, dynamic>{}
            : LearnRepository.map(videos.first);
        final thumbnail = _thumbnailValue(lesson);
        return ListView(
          children: [
            Text(
              'Course Lesson',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Learn step by step with expert-led video lessons.',
              style: TextStyle(color: context.palette.secondaryText),
            ),
            const SizedBox(height: 16),
            if (thumbnail.isNotEmpty) ...[
              CourseThumbnail(
                thumbnailPath: thumbnail,
                height: 190,
                showPlay: videos.isNotEmpty,
                durationSeconds: LearnRepository.number(
                  firstVideo['duration_seconds'],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 190,
                  color: context.palette.goldSoft,
                  child: Image.asset(
                    'assets/recovery_course_ui/course_video_placeholder_art.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (module.isNotEmpty)
              Text(
                LearnRepository.text(module['title']),
                style: TextStyle(
                  color: context.palette.goldText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (module.isNotEmpty) const SizedBox(height: 5),
            Text(
              LearnRepository.text(lesson['title'], 'TradeX Lesson'),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (course.isNotEmpty || firstVideo.isNotEmpty) ...[
              const SizedBox(height: 7),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  if (LearnRepository.number(firstVideo['duration_seconds']) >
                      0)
                    _LessonMeta(
                      icon: Icons.schedule_rounded,
                      label: _lessonDuration(
                        LearnRepository.number(firstVideo['duration_seconds']),
                      ),
                    ),
                  if (LearnRepository.text(lesson['difficulty']).isNotEmpty)
                    _LessonMeta(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: LearnRepository.text(lesson['difficulty']),
                    ),
                  if (LearnRepository.text(course['title']).isNotEmpty)
                    _LessonMeta(
                      icon: Icons.school_outlined,
                      label: LearnRepository.text(course['title']),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              LearnRepository.text(lesson['heading']),
              style: const TextStyle(color: TradeXColors.secondaryText),
            ),
            const SizedBox(height: 18),
            if (progress.isNotEmpty) ...[
              _LessonViewerProgress(progress: progress),
              const SizedBox(height: 16),
            ],
            LessonContentRenderer(
              lesson: lesson,
              videos: videos,
              repository: widget.repository,
              lessonUuid: widget.lessonUuid,
              progress: progress,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AskTradeXAiScreen(
                          repository: widget.repository,
                          lessonUuid: widget.lessonUuid,
                          lessonTitle: LearnRepository.text(lesson['title']),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Ask TradeX AI'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: ValueKey(
                      completed ? 'next-lesson-button' : 'mark-complete-button',
                    ),
                    onPressed: _completing
                        ? null
                        : completed && _nextLesson.isNotEmpty
                        ? () => _openNextLesson(_nextLesson)
                        : completed
                        ? null
                        : () => _completeLesson(data),
                    child: _completing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            completed
                                ? _nextLesson.isNotEmpty
                                      ? 'Next Lesson'
                                      : 'Completed'
                                : 'Mark as Complete',
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  Future<void> _completeLesson(JsonMap currentData) async {
    setState(() => _completing = true);
    try {
      await widget.repository.updateProgress(
        widget.lessonUuid,
        status: 'COMPLETED',
      );
      final refreshed = await widget.repository.lesson(widget.lessonUuid);
      var nextLesson = _nextLessonFromPayload(refreshed, widget.lessonUuid);
      if (nextLesson.isEmpty) {
        final course = LearnRepository.map(
          refreshed['course'] ??
              LearnRepository.map(refreshed['lesson'])['course'] ??
              currentData['course'] ??
              LearnRepository.map(currentData['lesson'])['course'],
        );
        final courseUuid = LearnRepository.text(course['uuid']);
        if (courseUuid.isNotEmpty) {
          final courseData = await widget.repository.course(courseUuid);
          nextLesson = _nextLessonFromModules(
            LearnRepository.list(courseData['modules']),
            widget.lessonUuid,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _completed = true;
        _nextLesson = nextLesson;
        _completing = false;
        future = Future<JsonMap>.value(refreshed);
      });
      ActivityTrackingScope.maybeOf(context)
          ?.track('learning', 'lesson_completed', subjectId: widget.lessonUuid);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lesson completed')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update lesson progress. Please retry.'),
        ),
      );
    }
  }

  void _openNextLesson(JsonMap lesson) {
    if (LearnRepository.flag(lesson['is_locked'])) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PremiumAccessScreen(repository: widget.repository),
        ),
      );
      return;
    }
    final uuid = LearnRepository.text(lesson['uuid']);
    if (uuid.isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => UniversalLessonViewerScreen(
          repository: widget.repository,
          lessonUuid: uuid,
        ),
      ),
    );
  }
}

JsonMap _nextLessonFromPayload(JsonMap payload, String currentUuid) {
  for (final candidate in <dynamic>[
    payload['next_lesson'],
    LearnRepository.map(payload['navigation'])['next_lesson'],
    LearnRepository.map(payload['navigation'])['next'],
    LearnRepository.map(payload['lesson'])['next_lesson'],
  ]) {
    final lesson = LearnRepository.map(candidate);
    if (LearnRepository.text(lesson['uuid']).isNotEmpty) return lesson;
  }
  final module = LearnRepository.map(
    payload['module'] ?? LearnRepository.map(payload['lesson'])['module'],
  );
  final fromModule = _nextLessonFromModules(<dynamic>[module], currentUuid);
  if (fromModule.isNotEmpty) return fromModule;
  return _nextLessonFromModules(
    LearnRepository.list(payload['modules']),
    currentUuid,
  );
}

JsonMap _nextLessonFromModules(List<dynamic> modules, String currentUuid) {
  final orderedLessons = <JsonMap>[];
  for (final rawModule in modules) {
    final module = LearnRepository.map(rawModule);
    orderedLessons.addAll(
      LearnRepository.list(module['lessons']).map(LearnRepository.map),
    );
  }
  final currentIndex = orderedLessons.indexWhere(
    (lesson) => LearnRepository.text(lesson['uuid']) == currentUuid,
  );
  if (currentIndex < 0 || currentIndex + 1 >= orderedLessons.length) {
    return const <String, dynamic>{};
  }
  return orderedLessons[currentIndex + 1];
}

class _LessonViewerProgress extends StatelessWidget {
  const _LessonViewerProgress({required this.progress});

  final JsonMap progress;

  @override
  Widget build(BuildContext context) {
    final percent = LearnRepository.number(progress['percent']).clamp(0, 100);
    final status = LearnRepository.text(progress['status'], 'IN PROGRESS');
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: context.palette.goldText,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 7,
            color: context.palette.gold,
            backgroundColor: context.palette.border,
          ),
        ],
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.palette.secondaryText),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(color: context.palette.secondaryText, fontSize: 12),
      ),
    ],
  );
}

String _lessonDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

class LessonContentRenderer extends StatelessWidget {
  const LessonContentRenderer({
    super.key,
    required this.lesson,
    required this.videos,
    required this.repository,
    required this.lessonUuid,
    required this.progress,
  });
  final JsonMap lesson;
  final List<dynamic> videos;
  final LearnRepository repository;
  final String lessonUuid;
  final JsonMap progress;
  @override
  Widget build(BuildContext context) {
    final body = LearnRepository.text(lesson['description']);
    if (videos.isNotEmpty && body.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextLessonRenderer(text: body),
          const SizedBox(height: 14),
          ...videos.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: VideoLessonRenderer(
                video: LearnRepository.map(v),
                repository: repository,
                lessonUuid: lessonUuid,
                resumeSeconds: _resumeSeconds(LearnRepository.map(v)),
              ),
            ),
          ),
        ],
      );
    }
    if (videos.isNotEmpty) {
      return Column(
        children: videos
            .map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VideoLessonRenderer(
                  video: LearnRepository.map(v),
                  repository: repository,
                  lessonUuid: lessonUuid,
                  resumeSeconds: _resumeSeconds(LearnRepository.map(v)),
                ),
              ),
            )
            .toList(),
      );
    }
    return TextLessonRenderer(
      text: body.isEmpty ? 'Lesson content is being prepared.' : body,
    );
  }

  int _resumeSeconds(JsonMap video) {
    final lastVideo = LearnRepository.text(progress['last_video_uuid']);
    final videoUuid = LearnRepository.text(video['uuid']);
    if (lastVideo.isNotEmpty && lastVideo != videoUuid) return 0;
    return LearnRepository.number(progress['last_position_seconds']);
  }
}

class TextLessonRenderer extends StatelessWidget {
  const TextLessonRenderer({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, color: context.palette.goldText),
            const SizedBox(width: 9),
            const Text(
              'Lesson Notes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(color: context.palette.secondaryText, height: 1.5),
          ),
        ],
      ],
    ),
  );
}

class ImageLessonRenderer extends StatelessWidget {
  const ImageLessonRenderer({super.key, required this.image});
  final ImageProvider image;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image(image: image, fit: BoxFit.contain),
  );
}

class PdfLessonRenderer extends StatelessWidget {
  const PdfLessonRenderer({super.key});
  @override
  Widget build(BuildContext context) => const _InfoCard(
    title: 'Protected PDF',
    body: 'This document is view-only inside TradeX. Download and sharing are disabled.',
  );
}

class VideoLessonRenderer extends StatefulWidget {
  const VideoLessonRenderer({
    super.key,
    required this.video,
    required this.repository,
    required this.lessonUuid,
    required this.resumeSeconds,
  });
  final JsonMap video;
  final LearnRepository repository;
  final String lessonUuid;
  final int resumeSeconds;
  @override
  State<VideoLessonRenderer> createState() => _VideoLessonRendererState();
}

class _VideoLessonRendererState extends State<VideoLessonRenderer> {
  bool loading = false;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: loading ? null : _openVideo,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.palette.goldSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: context.palette.goldText,
              size: 34,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LearnRepository.text(widget.video['title'], 'Secure video'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${LearnRepository.number(widget.video['duration_seconds']) ~/ 60} min • streaming only',
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            loading ? Icons.hourglass_top_rounded : Icons.chevron_right_rounded,
            color: context.palette.goldText,
          ),
        ],
      ),
    ),
  );

  Future<void> _openVideo() async {
    setState(() => loading = true);
    try {
      final token = await widget.repository.playbackToken(
        LearnRepository.text(widget.video['uuid']),
      );
      final playbackUrl = LearnRepository.text(token['playback_url']);
      if (playbackUrl.isNotEmpty && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CourseVideoPlayerScreen(
              repository: widget.repository,
              lessonUuid: widget.lessonUuid,
              videoUuid: LearnRepository.text(widget.video['uuid']),
              title: LearnRepository.text(
                widget.video['title'],
                'TradeX course video',
              ),
              playbackUrl: playbackUrl,
              resumeSeconds: widget.resumeSeconds,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
