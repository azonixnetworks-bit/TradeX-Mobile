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
  late Future<JsonMap> future = widget.repository.lesson(widget.lessonUuid);

  @override
  void initState() {
    super.initState();
    widget.repository.updateProgress(widget.lessonUuid, status: 'IN_PROGRESS');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ActivityTrackingScope.maybeOf(context)?.track(
        'learning',
        'lesson_viewed',
        subjectId: widget.lessonUuid,
      );
    });
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Lesson',
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
        return ListView(
          children: [
            if (_thumbnailValue(lesson).isNotEmpty) ...[
              CourseThumbnail(
                thumbnailPath: _thumbnailValue(lesson),
                height: 190,
                showPlay: videos.isNotEmpty,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              LearnRepository.text(lesson['title'], 'TradeX Lesson'),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              LearnRepository.text(lesson['heading']),
              style: const TextStyle(color: TradeXColors.secondaryText),
            ),
            const SizedBox(height: 18),
            LessonContentRenderer(
              lesson: lesson,
              videos: videos,
              repository: widget.repository,
              lessonUuid: widget.lessonUuid,
              progress: LearnRepository.map(data['progress']),
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
                    onPressed: () async {
                      await widget.repository.updateProgress(
                        widget.lessonUuid,
                        status: 'COMPLETED',
                      );
                      if (context.mounted) {
                        ActivityTrackingScope.maybeOf(context)?.track(
                          'learning',
                          'lesson_completed',
                          subjectId: widget.lessonUuid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lesson completed')),
                        );
                      }
                    },
                    child: const Text('Mark Complete'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
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
  Widget build(BuildContext context) =>
      _InfoCard(title: 'Lesson Notes', body: text);
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
    child: Row(
      children: [
        const Icon(Icons.play_circle_fill_rounded, color: _gold, size: 42),
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
        TextButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() => loading = true);
                  try {
                    final token = await widget.repository.playbackToken(
                      LearnRepository.text(widget.video['uuid']),
                    );
                    final playbackUrl = LearnRepository.text(
                      token['playback_url'],
                    );
                    if (playbackUrl.isNotEmpty && context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CourseVideoPlayerScreen(
                            repository: widget.repository,
                            lessonUuid: widget.lessonUuid,
                            videoUuid: LearnRepository.text(
                              widget.video['uuid'],
                            ),
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
                },
          child: Text(loading ? 'Loading…' : 'Play'),
        ),
      ],
    ),
  );
}
