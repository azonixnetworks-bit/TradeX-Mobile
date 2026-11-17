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
  int _selectedTab = 0;
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
        final thumbnail = _videoThumbnail(firstVideo, lesson);
        final assignments = LearnRepository.list(
          data['assignments'] ?? lesson['assignments'],
        );
        final resources = LearnRepository.list(
          data['resources'] ?? lesson['resources'] ?? lesson['attachments'],
        );
        return ListView(
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            _CompactLessonCourseInfo(course: course, module: module),
            const SizedBox(height: 12),
            if (firstVideo.isNotEmpty)
              _LessonVideoSection(
                repository: widget.repository,
                lessonUuid: widget.lessonUuid,
                video: firstVideo,
                thumbnail: thumbnail,
                resumeSeconds: LearnRepository.number(
                  progress['last_position_seconds'],
                ),
              )
            else
              _LessonVideoEmpty(thumbnail: thumbnail),
            const SizedBox(height: 14),
            Text(
              LearnRepository.text(lesson['title'], 'TradeX Lesson'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.palette.primaryText,
                fontWeight: FontWeight.w900,
              ),
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
            if (LearnRepository.text(lesson['heading']).isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                LearnRepository.text(lesson['heading']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.palette.secondaryText),
              ),
            ],
            const SizedBox(height: 14),
            _LessonTabs(
              selected: _selectedTab,
              onSelected: (value) => setState(() => _selectedTab = value),
            ),
            const SizedBox(height: 12),
            _LessonTabBody(
              selected: _selectedTab,
              lesson: lesson,
              assignments: assignments,
              resources: resources,
              repository: widget.repository,
            ),
            const SizedBox(height: 16),
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

class _CompactLessonCourseInfo extends StatelessWidget {
  const _CompactLessonCourseInfo({required this.course, required this.module});
  final JsonMap course, module;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.palette.goldSoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(Icons.school_outlined, color: context.palette.goldText),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LearnRepository.text(course['title'], 'TradeX Course'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.palette.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (LearnRepository.text(module['title']).isNotEmpty)
              Text(
                LearnRepository.text(module['title']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.palette.secondaryText),
              ),
          ],
        ),
      ),
    ],
  );
}

class _LessonVideoSection extends StatefulWidget {
  const _LessonVideoSection({
    required this.repository,
    required this.lessonUuid,
    required this.video,
    required this.thumbnail,
    required this.resumeSeconds,
  });
  final LearnRepository repository;
  final String lessonUuid, thumbnail;
  final JsonMap video;
  final int resumeSeconds;
  @override
  State<_LessonVideoSection> createState() => _LessonVideoSectionState();
}

class _LessonVideoSectionState extends State<_LessonVideoSection> {
  late Future<JsonMap> token = widget.repository.playbackToken(
    LearnRepository.text(widget.video['uuid']),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<JsonMap>(
    future: token,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: PlayerError(
            onRetry: () => setState(
              () => token = widget.repository.playbackToken(
                LearnRepository.text(widget.video['uuid']),
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return _LessonVideoLoading(thumbnail: widget.thumbnail);
      }
      final sources = playbackSources(snapshot.data!);
      if (sources.isEmpty) {
        return _LessonVideoEmpty(thumbnail: widget.thumbnail);
      }
      return TradeXVideoPlayer(
        repository: widget.repository,
        lessonUuid: widget.lessonUuid,
        videoUuid: LearnRepository.text(widget.video['uuid']),
        sources: sources,
        thumbnailPath: widget.thumbnail,
        resumeSeconds: widget.resumeSeconds,
        onFullscreen: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CourseVideoPlayerScreen(
              repository: widget.repository,
              lessonUuid: widget.lessonUuid,
              videoUuid: LearnRepository.text(widget.video['uuid']),
              title: LearnRepository.text(
                widget.video['title'],
                'Course video',
              ),
              playbackUrl: sources.values.first,
              sources: sources,
              thumbnailPath: widget.thumbnail,
              resumeSeconds: widget.resumeSeconds,
              startFullscreen: true,
            ),
          ),
        ),
      );
    },
  );
}

class _LessonVideoLoading extends StatelessWidget {
  const _LessonVideoLoading({required this.thumbnail});
  final String thumbnail;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnail.isNotEmpty)
          CourseThumbnail(thumbnailPath: thumbnail, height: double.infinity)
        else
          ColoredBox(color: context.palette.goldSoft),
        const Center(
          child: CircularProgressIndicator(color: TradeXColors.goldBright),
        ),
      ],
    ),
  );
}

class _LessonVideoEmpty extends StatelessWidget {
  const _LessonVideoEmpty({required this.thumbnail});
  final String thumbnail;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: TradeXRadii.card,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: thumbnail.isNotEmpty
          ? CourseThumbnail(thumbnailPath: thumbnail, height: double.infinity)
          : ColoredBox(
              color: context.palette.goldSoft,
              child: Icon(
                Icons.video_library_outlined,
                color: context.palette.goldText,
                size: 44,
              ),
            ),
    ),
  );
}

class _LessonTabs extends StatelessWidget {
  const _LessonTabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    segments: const [
      ButtonSegment(value: 0, label: Text('Lesson Notes')),
      ButtonSegment(value: 1, label: Text('Assignment')),
      ButtonSegment(value: 2, label: Text('Resources')),
    ],
    selected: <int>{selected},
    showSelectedIcon: false,
    onSelectionChanged: (value) => onSelected(value.first),
  );
}

class _LessonTabBody extends StatelessWidget {
  const _LessonTabBody({
    required this.selected,
    required this.lesson,
    required this.assignments,
    required this.resources,
    required this.repository,
  });
  final int selected;
  final JsonMap lesson;
  final List<dynamic> assignments, resources;
  final LearnRepository repository;

  @override
  Widget build(BuildContext context) {
    if (selected == 1) {
      if (assignments.isEmpty) {
        return const _LessonTabEmpty(
          icon: Icons.assignment_outlined,
          message: 'No assignment is available for this lesson.',
        );
      }
      return Column(
        children: assignments.map((raw) {
          final assignment = LearnRepository.map(raw);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PremiumCard(
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.assignment_outlined,
                    color: context.palette.goldText,
                  ),
                  title: Text(
                    LearnRepository.text(assignment['title'], 'Assignment'),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: LearnRepository.text(assignment['uuid']).isEmpty
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => AssignmentDetailsScreen(
                              repository: repository,
                              assignmentUuid: LearnRepository.text(
                                assignment['uuid'],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
    if (selected == 2) {
      if (resources.isEmpty) {
        return const _LessonTabEmpty(
          icon: Icons.folder_open_outlined,
          message: 'No resources are available for this lesson.',
        );
      }
      return Column(
        children: resources.map((raw) {
          final resource = LearnRepository.map(raw);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PremiumCard(
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: context.palette.goldText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LearnRepository.text(
                        resource['title'],
                        LearnRepository.text(resource['name'], 'Resource'),
                      ),
                      style: TextStyle(color: context.palette.primaryText),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
    final notes = LearnRepository.text(
      lesson['notes'],
      LearnRepository.text(lesson['description']),
    );
    return _ExpandableLessonNotes(notes: notes);
  }
}

class _ExpandableLessonNotes extends StatefulWidget {
  const _ExpandableLessonNotes({required this.notes});
  final String notes;
  @override
  State<_ExpandableLessonNotes> createState() => _ExpandableLessonNotesState();
}

class _ExpandableLessonNotesState extends State<_ExpandableLessonNotes> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return const _LessonTabEmpty(
        icon: Icons.notes_rounded,
        message: 'Lesson notes are not available yet.',
      );
    }
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.notes,
            maxLines: expanded ? null : 5,
            overflow: expanded ? null : TextOverflow.ellipsis,
            style: TextStyle(color: context.palette.primaryText, height: 1.5),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('lesson-notes-toggle'),
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Show Less' : 'Read More'),
          ),
        ],
      ),
    );
  }
}

class _LessonTabEmpty extends StatelessWidget {
  const _LessonTabEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Row(
      children: [
        Icon(icon, color: context.palette.goldText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: context.palette.secondaryText),
          ),
        ),
      ],
    ),
  );
}

String _videoThumbnail(JsonMap video, JsonMap lesson) {
  for (final value in <dynamic>[
    video['thumbnail_url'],
    video['thumbnail_path'],
    video['poster_url'],
    video['poster_path'],
    lesson['thumbnail_url'],
    lesson['thumbnail_path'],
  ]) {
    final thumbnail = LearnRepository.text(value);
    if (thumbnail.isNotEmpty) return thumbnail;
  }
  return '';
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
