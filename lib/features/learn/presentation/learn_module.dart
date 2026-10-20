import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/preferences/app_preferences.dart';
import '../data/learn_repository.dart';
import 'course_video_player_screen.dart';
import '../../catalog/presentation/secure_workflow_screens.dart';

const _gold = TradeXColors.goldBright;

class LearnHomeScreen extends StatefulWidget {
  const LearnHomeScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  State<LearnHomeScreen> createState() => _LearnHomeScreenState();
}

class _LearnHomeScreenState extends State<LearnHomeScreen> {
  late Future<JsonMap> _future = widget.repository.overview();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLanguage());
  }

  Future<void> _ensureLanguage() async {
    if (AppPreferences.instance.learnLanguageSelected || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => LearnLanguageSelectionScreen(
          repository: widget.repository,
          firstEntry: true,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  void _refresh() => setState(() => _future = widget.repository.overview());
  void _open(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen))
          .then((_) => _refresh());

  @override
  Widget build(BuildContext context) => _FutureBody(
    future: _future,
    onRetry: _refresh,
    builder: (data) {
      final learning = LearnRepository.map(data['learning']);
      final isPremium = LearnRepository.flag(data['is_premium']);
      final continueItem = LearnRepository.map(learning['continue_learning']);
      final starter = LearnRepository.map(learning['default_premium_lesson']);
      final freeLessons = LearnRepository.list(learning['free_lessons']);
      final featured = LearnRepository.list(data['featured_courses']);
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: _gold,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _PageHeading(
              title: 'Learn',
              subtitle: 'Build skill, discipline and consistency.',
            ),
            const SizedBox(height: 18),
            _SectionHeading(
              icon: Icons.play_circle_fill_rounded,
              title: 'Continue Learning',
              action: 'My Learning',
              onTap: () =>
                  _open(MyLearningScreen(repository: widget.repository)),
            ),
            const SizedBox(height: 10),
            if (!isPremium)
              _PremiumLockCard(
                onTap: () =>
                    _open(PremiumAccessScreen(repository: widget.repository)),
              )
            else if (continueItem.isNotEmpty)
              _LearningCard(
                item: continueItem,
                button: 'Continue',
                onTap: () => _openLessonFromItem(continueItem),
              )
            else
              _LearningCard(
                item: starter,
                button: 'Start Learning',
                emptyTitle: 'Start Your Learning Journey',
                onTap: starter.isEmpty
                    ? null
                    : () => _openLessonFromItem(starter),
              ),
            const SizedBox(height: 22),
            _ShortcutGrid(
              onCourses: () =>
                  _open(SubjectsScreen(repository: widget.repository)),
              onProgress: () =>
                  _open(LearningProgressScreen(repository: widget.repository)),
              onAssignments: () =>
                  _open(AssignmentsScreen(repository: widget.repository)),
              onAi: () =>
                  _open(AskTradeXAiScreen(repository: widget.repository)),
              onSettings: () =>
                  _open(LearnSettingsScreen(repository: widget.repository)),
              onSaved: () => _open(
                MyLearningScreen(
                  repository: widget.repository,
                  initialIndex: 3,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              icon: Icons.auto_stories_rounded,
              title: 'Free Lessons',
              action: 'View all',
              onTap: () => _open(
                SubjectsScreen(
                  repository: widget.repository,
                  initialAccess: 'FREE',
                ),
              ),
            ),
            const SizedBox(height: 10),
            _HorizontalCards(
              items: freeLessons,
              empty: 'No free lessons are published yet.',
              builder: (item) => _LearningCard(
                item: LearnRepository.map(item),
                compact: true,
                badge: 'FREE',
                onTap: () => _openLessonFromItem(LearnRepository.map(item)),
              ),
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              icon: Icons.school_rounded,
              title: 'Featured Courses',
              action: 'All courses',
              onTap: () => _open(SubjectsScreen(repository: widget.repository)),
            ),
            const SizedBox(height: 10),
            _HorizontalCards(
              items: featured,
              empty: 'Courses will appear here when published.',
              builder: (item) {
                final course = LearnRepository.map(item);
                return _CourseCard(
                  course: course,
                  compact: true,
                  onTap: () => _open(
                    SubjectDetailsScreen(
                      repository: widget.repository,
                      courseUuid: LearnRepository.text(course['uuid']),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            _ProgressSummary(
              completed: LearnRepository.number(learning['completed_lessons']),
              total: LearnRepository.number(
                learning['accessible_published_lessons'],
              ),
              percent: LearnRepository.number(learning['completion_percent']),
              onTap: () =>
                  _open(LearningProgressScreen(repository: widget.repository)),
            ),
          ],
        ),
      );
    },
  );

  void _openLessonFromItem(JsonMap item) {
    final lesson = LearnRepository.map(item['lesson']);
    final uuid = LearnRepository.text(
      lesson['uuid'],
      LearnRepository.text(item['lesson_uuid']),
    );
    if (uuid.isEmpty) return;
    _open(
      UniversalLessonViewerScreen(
        repository: widget.repository,
        lessonUuid: uuid,
      ),
    );
  }
}

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({
    super.key,
    required this.repository,
    this.initialAccess = '',
  });
  final LearnRepository repository;
  final String initialAccess;
  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String search = '';
  late String access = widget.initialAccess;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Subjects & Courses',
    child: Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => search = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search courses',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['', 'FREE', 'PREMIUM']
              .map(
                (value) => ChoiceChip(
                  label: Text(value.isEmpty ? 'All' : value),
                  selected: access == value,
                  onSelected: (_) => setState(() => access = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _FutureBody(
            key: ValueKey('$search-$access'),
            future: widget.repository.courses(search: search, access: access),
            builder: (data) {
              final items = LearnRepository.list(data['items']);
              if (items.isEmpty) {
                return const _EmptyState('No matching courses found.');
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final course = LearnRepository.map(items[index]);
                  return _CourseCard(
                    course: course,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => SubjectDetailsScreen(
                          repository: widget.repository,
                          courseUuid: LearnRepository.text(course['uuid']),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class SubjectDetailsScreen extends StatelessWidget {
  const SubjectDetailsScreen({
    super.key,
    required this.repository,
    required this.courseUuid,
  });
  final LearnRepository repository;
  final String courseUuid;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Subject Details',
    child: _FutureBody(
      future: repository.course(courseUuid),
      builder: (data) {
        final course = LearnRepository.map(data['course']);
        final modules = LearnRepository.list(data['modules']);
        return ListView(
          children: [
            _CourseHero(course: course),
            const SizedBox(height: 18),
            const _SectionHeading(
              icon: Icons.view_module_rounded,
              title: 'Modules',
            ),
            const SizedBox(height: 10),
            if (modules.isEmpty) const _EmptyState('No modules available yet.'),
            ...modules.map((raw) {
              final module = LearnRepository.map(raw);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ModuleCard(
                  module: module,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ModuleLessonsScreen(
                        repository: repository,
                        moduleUuid: LearnRepository.text(module['uuid']),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    ),
  );
}

class ModuleLessonsScreen extends StatelessWidget {
  const ModuleLessonsScreen({
    super.key,
    required this.repository,
    required this.moduleUuid,
  });
  final LearnRepository repository;
  final String moduleUuid;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Module Lessons',
    child: _FutureBody(
      future: repository.module(moduleUuid),
      builder: (data) {
        final module = LearnRepository.map(data['module']);
        final lessons = LearnRepository.list(data['lessons']);
        return ListView(
          children: [
            _InfoCard(
              title: LearnRepository.text(module['title'], 'Module'),
              body: LearnRepository.text(
                module['description'],
                LearnRepository.text(module['short_description']),
              ),
            ),
            const SizedBox(height: 14),
            ...lessons.map((raw) {
              final lesson = LearnRepository.map(raw);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LessonCard(
                  lesson: lesson,
                  onTap: () {
                    if (LearnRepository.flag(lesson['is_locked'])) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PremiumAccessScreen(repository: repository),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => UniversalLessonViewerScreen(
                            repository: repository,
                            lessonUuid: LearnRepository.text(lesson['uuid']),
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        );
      },
    ),
  );
}

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

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({
    super.key,
    required this.repository,
    this.initialIndex = 0,
  });
  final LearnRepository repository;
  final int initialIndex;
  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.initialIndex,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'My Learning',
    child: Column(
      children: [
        TabBar(
          controller: controller,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Continue'),
            Tab(text: 'Recent'),
            Tab(text: 'Completed'),
            Tab(text: 'Saved'),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: ['CONTINUE', 'RECENT', 'COMPLETED', 'SAVED']
                .map(
                  (view) =>
                      _LearningList(repository: widget.repository, view: view),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class _LearningList extends StatelessWidget {
  const _LearningList({required this.repository, required this.view});
  final LearnRepository repository;
  final String view;
  @override
  Widget build(BuildContext context) => _FutureBody(
    future: repository.myLearning(view),
    builder: (data) {
      final items = LearnRepository.list(data['items']);
      if (items.isEmpty) {
        return _EmptyState(
          view == 'SAVED'
              ? 'No saved lessons yet.'
              : 'No learning activity here yet.',
        );
      }
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = LearnRepository.map(items[i]);
          return _LearningCard(
            item: item,
            onTap: () {
              final lesson = LearnRepository.map(item['lesson']);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UniversalLessonViewerScreen(
                    repository: repository,
                    lessonUuid: LearnRepository.text(lesson['uuid']),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

class AskTradeXAiScreen extends StatefulWidget {
  const AskTradeXAiScreen({
    super.key,
    required this.repository,
    this.lessonUuid,
    this.lessonTitle,
  });
  final LearnRepository repository;
  final String? lessonUuid;
  final String? lessonTitle;
  @override
  State<AskTradeXAiScreen> createState() => _AskTradeXAiScreenState();
}

class _AskTradeXAiScreenState extends State<AskTradeXAiScreen> {
  final controller = TextEditingController();
  JsonMap? answer;
  bool loading = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Ask TradeX AI',
    child: Column(
      children: [
        if (widget.lessonTitle != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text('Based on: ${widget.lessonTitle}')),
          ),
        Expanded(
          child: ListView(
            children: [
              const _InfoCard(
                title: 'TradeX Second Brain',
                body: 'Answers prioritize founder-approved TradeX course knowledge. Generic internet content is not silently substituted.',
              ),
              if (answer != null) ...[
                const SizedBox(height: 14),
                _InfoCard(
                  title: 'Answer',
                  body: LearnRepository.text(answer!['answer']),
                ),
                ...LearnRepository.list(answer!['sources']).map(
                  (source) => ListTile(
                    leading: const Icon(Icons.verified_rounded, color: _gold),
                    title: Text(
                      LearnRepository.text(
                        LearnRepository.map(source)['title'],
                      ),
                    ),
                    subtitle: const Text('Approved TradeX source'),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ask about this lesson…',
                ),
              ),
            ),
            IconButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (controller.text.trim().length < 3) return;
                      setState(() => loading = true);
                      try {
                        answer = await widget.repository.askAi(
                          controller.text.trim(),
                          lessonUuid: widget.lessonUuid,
                        );
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              icon: loading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.send_rounded, color: _gold),
            ),
          ],
        ),
      ],
    ),
  );
}

class PremiumAccessScreen extends StatefulWidget {
  const PremiumAccessScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
}

class _PremiumAccessScreenState extends State<PremiumAccessScreen> {
  late Future<JsonMap> future = widget.repository.premiumAccess();

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Premium Access',
    child: _FutureBody(
      future: future,
      onRetry: _reload,
      builder: (data) {
        final products = LearnRepository.map(data['products']);
        final activation = LearnRepository.map(data['activation']);
        final items = LearnRepository.list(products['items']).isNotEmpty
            ? LearnRepository.list(products['items'])
            : LearnRepository.list(products['products']);
        return ListView(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: _gold, size: 72),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Membership status',
              body: LearnRepository.text(
                activation['status'],
                LearnRepository.flag(activation['premium_active']) ||
                        LearnRepository.flag(activation['is_active'])
                    ? 'Active'
                    : 'No active entitlement',
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const _InfoCard(
                title: 'No offer available',
                body: 'TradeX has not published a purchasable product for this account.',
              )
            else
              for (final raw in items) ...[
                _ProductOfferCard(
                  product: LearnRepository.map(raw),
                  onPurchase: _openCheckout,
                ),
                const SizedBox(height: 12),
              ],
            const _InfoCard(
              title: 'Verified access only',
              body: 'Premium lessons unlock only after TradeX confirms payment and the education API returns an active entitlement.',
            ),
          ],
        );
      },
    ),
  );

  void _reload() => setState(() => future = widget.repository.premiumAccess());

  Future<void> _openCheckout(String productUuid) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentCheckoutScreen(
          apiClient: widget.repository.apiClient,
          productUuid: productUuid,
        ),
      ),
    );
    if (mounted) _reload();
  }
}

class _ProductOfferCard extends StatelessWidget {
  const _ProductOfferCard({required this.product, required this.onPurchase});
  final JsonMap product;
  final ValueChanged<String> onPurchase;

  @override
  Widget build(BuildContext context) {
    final uuid = LearnRepository.text(product['uuid']);
    final price = LearnRepository.map(product['price']);
    final amount = LearnRepository.text(
      product['formatted_price'],
      LearnRepository.text(price['amount']),
    );
    final currency = LearnRepository.text(
      product['currency'],
      LearnRepository.text(price['currency']),
    );
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LearnRepository.text(product['name'], 'TradeX membership'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (amount.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$currency $amount'.trim(),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            LearnRepository.text(product['description']),
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: uuid.isEmpty ? null : () => onPurchase(uuid),
            child: const Text('Choose payment method'),
          ),
        ],
      ),
    );
  }
}

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({super.key, required this.repository});
  final LearnRepository repository;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Learning Progress',
    child: _FutureBody(
      future: repository.progress(),
      builder: (data) {
        final overall = LearnRepository.map(data['overall']);
        final courses = LearnRepository.list(data['courses']);
        final history = LearnRepository.list(data['recent_completions']);
        return ListView(
          children: [
            _ProgressSummary(
              completed: LearnRepository.number(overall['completed_lessons']),
              total: LearnRepository.number(overall['total_lessons']),
              percent: LearnRepository.number(overall['percent']),
            ),
            const SizedBox(height: 18),
            const _SectionHeading(icon: Icons.school, title: 'Active Courses'),
            const SizedBox(height: 8),
            ...courses.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CourseCard(course: LearnRepository.map(c)),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionHeading(
              icon: Icons.history,
              title: 'Recent Completions',
            ),
            ...history.map(
              (item) => ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: TradeXColors.success,
                ),
                title: Text(
                  LearnRepository.text(
                    LearnRepository.map(
                      LearnRepository.map(item)['lesson'],
                    )['title'],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class LearnSettingsScreen extends StatefulWidget {
  const LearnSettingsScreen({super.key, required this.repository});
  final LearnRepository repository;
  @override
  State<LearnSettingsScreen> createState() => _LearnSettingsScreenState();
}

class _LearnSettingsScreenState extends State<LearnSettingsScreen> {
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Learn Settings',
    child: ListView(
      children: [
        const _InfoCard(
          title: 'Learning Preferences',
          body: 'Choose the preferred display language for supported TradeX course translations.',
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.language_rounded, color: _gold),
          title: const Text('Course language'),
          subtitle: Text(AppPreferences.instance.courseLanguage.toUpperCase()),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    LearnLanguageSelectionScreen(repository: widget.repository),
              ),
            );
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 12),
        const _SectionHeading(
          icon: Icons.palette_outlined,
          title: 'Appearance',
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_suggest_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {AppPreferences.instance.themeMode},
          onSelectionChanged: (selection) async {
            await AppPreferences.instance.setThemeMode(selection.first);
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.cloud_off_rounded, color: _gold),
          title: Text('Protected online learning'),
          subtitle: Text('Downloads and offline exports are disabled.'),
        ),
      ],
    ),
  );
}

class LearnLanguageSelectionScreen extends StatefulWidget {
  const LearnLanguageSelectionScreen({
    super.key,
    required this.repository,
    this.firstEntry = false,
  });

  final LearnRepository repository;
  final bool firstEntry;

  @override
  State<LearnLanguageSelectionScreen> createState() =>
      _LearnLanguageSelectionScreenState();
}

class _LearnLanguageSelectionScreenState
    extends State<LearnLanguageSelectionScreen> {
  late Future<JsonMap> _future = widget.repository.languages();
  String selected = AppPreferences.instance.courseLanguage;
  bool saving = false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.firstEntry || AppPreferences.instance.learnLanguageSelected,
    child: _LearnScaffold(
      title: widget.firstEntry ? 'Choose Course Language' : 'Course Language',
      child: _FutureBody(
        future: _future,
        onRetry: () => setState(() => _future = widget.repository.languages()),
        builder: (data) {
          final languages = _languageEntries(data);
          return ListView(
            children: [
              const _InfoCard(
                title: 'Learn in your language',
                body: 'TradeX will show translated course content when it is published. You can change this later in Learn Settings.',
              ),
              const SizedBox(height: 12),
              for (final language in languages)
                ListTile(
                  leading: Icon(
                    selected == language.$1
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected == language.$1
                        ? _gold
                        : TradeXColors.secondaryText,
                  ),
                  title: Text(language.$2),
                  subtitle: Text(language.$1.toUpperCase()),
                  onTap: () => setState(() => selected = language.$1),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(saving ? 'Saving…' : 'Continue'),
              ),
            ],
          );
        },
      ),
    ),
  );

  List<(String, String)> _languageEntries(JsonMap data) {
    final raw = LearnRepository.list(data['languages']).isNotEmpty
        ? LearnRepository.list(data['languages'])
        : LearnRepository.list(data['items']).isNotEmpty
        ? LearnRepository.list(data['items'])
        : data.values.whereType<Map>().toList();
    final parsed = raw
        .map(LearnRepository.map)
        .map(
          (item) => (
            LearnRepository.text(
              item['code'],
              LearnRepository.text(item['language_code']),
            ).toLowerCase(),
            LearnRepository.text(
              item['native_name'],
              LearnRepository.text(item['name'], 'Language'),
            ),
          ),
        )
        .where((item) => item.$1.isNotEmpty)
        .toList(growable: false);
    return parsed.isEmpty ? const [('en', 'English')] : parsed;
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.repository.updateLanguage(selected);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key, required this.repository});
  final LearnRepository repository;
  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String status = 'ALL';
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Assignments',
    child: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'PENDING', 'SUBMITTED', 'REVIEWED']
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: status == value,
                      onSelected: (_) => setState(() => status = value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _FutureBody(
            key: ValueKey(status),
            future: widget.repository.assignments(status),
            builder: (data) {
              final items = LearnRepository.list(data['items']);
              if (items.isEmpty) {
                return const _EmptyState('No assignments available.');
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (_, i) {
                  final assignment = LearnRepository.map(items[i]);
                  return _PremiumCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.assignment_rounded,
                        color: _gold,
                      ),
                      title: Text(LearnRepository.text(assignment['title'])),
                      subtitle: Text(
                        '${LearnRepository.text(LearnRepository.map(assignment['course'])['title'])} • ${LearnRepository.text(assignment['state'], 'PENDING')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AssignmentDetailsScreen(
                            repository: widget.repository,
                            assignmentUuid: LearnRepository.text(
                              assignment['uuid'],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class AssignmentDetailsScreen extends StatelessWidget {
  const AssignmentDetailsScreen({
    super.key,
    required this.repository,
    required this.assignmentUuid,
  });
  final LearnRepository repository;
  final String assignmentUuid;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Assignment Details',
    child: _FutureBody(
      future: repository.assignment(assignmentUuid),
      builder: (data) {
        final assignment = LearnRepository.map(
          data['assignment'].toString().isEmpty ? data : data['assignment'],
        );
        return ListView(
          children: [
            _InfoCard(
              title: LearnRepository.text(assignment['title'], 'Assignment'),
              body: LearnRepository.text(
                assignment['description'],
                LearnRepository.text(
                  assignment['submission_instructions'],
                  'Follow the assignment instructions and submit through the approved channel.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Submission',
              body: 'TradeX currently uses secure external WhatsApp submission. The app does not upload learner files or claim a submitted/reviewed state until the backend supports verified review tracking.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final result = await repository.whatsappAction(assignmentUuid);
                final uri = Uri.tryParse(
                  LearnRepository.text(
                    result['url'],
                    LearnRepository.text(result['whatsapp_url']),
                  ),
                );
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Continue in WhatsApp'),
            ),
          ],
        );
      },
    ),
  );
}

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
  Widget build(BuildContext context) => FutureBuilder<JsonMap>(
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

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: TradeXColors.secondaryText)),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.action,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onTap;
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
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
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

class _PremiumLockCard extends StatelessWidget {
  const _PremiumLockCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      children: [
        const Icon(Icons.lock_rounded, color: _gold, size: 36),
        const SizedBox(height: 8),
        const Text(
          'Premium content. Upgrade to continue learning.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.workspace_premium),
          label: const Text('Unlock Premium'),
        ),
      ],
    ),
  );
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.item,
    this.onTap,
    this.button,
    this.emptyTitle,
    this.compact = false,
    this.badge,
  });
  final JsonMap item;
  final VoidCallback? onTap;
  final String? button;
  final String? emptyTitle;
  final bool compact;
  final String? badge;
  @override
  Widget build(BuildContext context) {
    final lesson = LearnRepository.map(item['lesson']);
    final module = LearnRepository.map(item['module']);
    final course = LearnRepository.map(item['course']);
    final title = LearnRepository.text(
      lesson['title'],
      LearnRepository.text(
        item['lesson_title'],
        emptyTitle ?? 'Start learning',
      ),
    );
    final percent = LearnRepository.number(item['progress_percent']);
    return SizedBox(
      width: compact ? 270 : null,
      child: _PremiumCard(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null) _StatusBadge(badge!),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
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
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: percent.clamp(0, 100) / 100,
                color: _gold,
                backgroundColor: TradeXColors.border,
              ),
              if (button != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    button!,
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, this.onTap, this.compact = false});
  final JsonMap course;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final locked = LearnRepository.flag(course['is_locked']);
    final progress = LearnRepository.map(course['progress']);
    return SizedBox(
      width: compact ? 275 : null,
      child: _PremiumCard(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});
  final JsonMap course;
  @override
  Widget build(BuildContext context) => _InfoCard(
    title: LearnRepository.text(course['title'], 'TradeX Course'),
    body: LearnRepository.text(
      course['description'],
      LearnRepository.text(course['short_description']),
    ),
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});
  final JsonMap module;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
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

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});
  final JsonMap lesson;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final locked = LearnRepository.flag(lesson['is_locked']);
    final progress = LearnRepository.map(lesson['progress']);
    return _PremiumCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
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

class _HorizontalCards extends StatelessWidget {
  const _HorizontalCards({
    required this.items,
    required this.builder,
    required this.empty,
  });
  final List<dynamic> items;
  final Widget Function(dynamic) builder;
  final String empty;
  @override
  Widget build(BuildContext context) => items.isEmpty
      ? _EmptyState(empty)
      : SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => builder(items[i]),
          ),
        );
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({
    required this.onCourses,
    required this.onProgress,
    required this.onAssignments,
    required this.onAi,
    required this.onSettings,
    required this.onSaved,
  });
  final VoidCallback onCourses,
      onProgress,
      onAssignments,
      onAi,
      onSettings,
      onSaved;
  @override
  Widget build(BuildContext context) {
    final entries = [
      (Icons.school, 'Courses', onCourses),
      (Icons.insights, 'Progress', onProgress),
      (Icons.assignment, 'Assignments', onAssignments),
      (Icons.auto_awesome, 'Ask AI', onAi),
      (Icons.bookmark, 'Saved', onSaved),
      (Icons.settings, 'Settings', onSettings),
    ];
    return LayoutBuilder(
      builder: (_, box) {
        final width = (box.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: entries
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: _PremiumCard(
                    child: InkWell(
                      onTap: entry.$3,
                      child: Column(
                        children: [
                          Icon(entry.$1, color: _gold),
                          const SizedBox(height: 6),
                          Text(
                            entry.$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.completed,
    required this.total,
    required this.percent,
    this.onTap,
  });
  final int completed, total, percent;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: InkWell(
      onTap: onTap,
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
