part of '../learn_module.dart';

class LearnHomeScreen extends StatefulWidget {
  const LearnHomeScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  State<LearnHomeScreen> createState() => _LearnHomeScreenState();
}

class _LearnHomeScreenState extends State<LearnHomeScreen> {
  late Future<_LearnDashboardData> _future;
  String? _resumingLessonUuid;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLanguage());
  }

  Future<_LearnDashboardData> _loadDashboard() async {
    final overview = await widget.repository.overview();
    final bookmarked = <String>{};
    try {
      final saved = await widget.repository.myLearning('SAVED');
      for (final raw in LearnRepository.list(saved['items'])) {
        final item = LearnRepository.map(raw);
        final lesson = LearnRepository.map(item['lesson']);
        final uuid = LearnRepository.text(
          lesson['uuid'],
          LearnRepository.text(item['lesson_uuid']),
        );
        if (uuid.isNotEmpty) bookmarked.add(uuid);
      }
    } catch (_) {
      // The overview remains usable when the optional bookmark lookup fails.
    }
    return _LearnDashboardData(overview: overview, bookmarked: bookmarked);
  }

  Future<void> _ensureLanguage() async {
    if (widget.repository.learnLanguageSelected || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => LearnLanguageSelectionScreen(
          repository: widget.repository,
          firstEntry: true,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _refresh() async {
    final next = _loadDashboard();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => BlocFutureBuilder<_LearnDashboardData>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const ColoredBox(
          color: learnBackground,
          child: Center(child: CircularProgressIndicator(color: learnGold)),
        );
      }
      if (snapshot.hasError || snapshot.data == null) {
        return ColoredBox(
          color: learnBackground,
          child: _ErrorState(
            onRetry: _refresh,
            message: snapshot.error.toString(),
          ),
        );
      }
      final dashboard = snapshot.data!;
      final data = dashboard.overview;
      final learning = LearnRepository.map(data['learning']);
      final isPremium = LearnRepository.flag(data['is_premium']);
      final continueItem = LearnRepository.map(learning['continue_learning']);
      final freeLessons = LearnRepository.list(learning['free_lessons']);
      final featured = LearnRepository.list(data['featured_courses']);
      final premiumStarter = LearnRepository.map(
        learning['default_premium_lesson'],
      );
      final starter = premiumStarter.isNotEmpty
          ? premiumStarter
          : freeLessons.isNotEmpty
          ? LearnRepository.map(freeLessons.first)
          : <String, dynamic>{};
      return RefreshIndicator(
        onRefresh: _refresh,
        color: learnGold,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [learnBackground, TradeXColors.backgroundSoft],
            ),
          ),
          child: ListView(
            key: const ValueKey('learn-dashboard-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
            children: [
              const LearnDashboardHeader(),
              const SizedBox(height: 22),
              LearningSectionHeader(
                icon: Icons.play_arrow_rounded,
                title: 'Continue Learning',
                action: 'My Learning',
                onAction: () =>
                    _open(MyLearningScreen(repository: widget.repository)),
              ),
              const SizedBox(height: 10),
              if (continueItem.isNotEmpty)
                ContinueLearningCard(
                  item: continueItem,
                  loading: _resumingLessonUuid == _lessonUuid(continueItem),
                  onContinue: () => _resumeLearning(continueItem),
                ),
              if (continueItem.isEmpty && starter.isNotEmpty)
                ContinueLearningCard(
                  item: starter,
                  starting: true,
                  onContinue: () => _openLessonFromItem(starter),
                ),
              if (continueItem.isEmpty && starter.isEmpty)
                LearningEmptyState(
                  title: 'Start Your Learning Journey',
                  message: isPremium
                      ? 'Published lessons will appear here when available.'
                      : 'No accessible free lessons are published yet.',
                  action: 'Browse Courses',
                  onAction: () =>
                      _open(SubjectsScreen(repository: widget.repository)),
                ),
              const SizedBox(height: 18),
              LearningShortcutGrid(items: _shortcuts()),
              const SizedBox(height: 23),
              LearningSectionHeader(
                icon: Icons.menu_book_rounded,
                title: 'Free Lessons',
                action: 'View all',
                onAction: () => _open(
                  SubjectsScreen(
                    repository: widget.repository,
                    initialAccess: 'FREE',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (freeLessons.isEmpty)
                const LearningEmptyState(
                  title: 'No free lessons yet',
                  message: 'Published free lessons will appear here.',
                )
              else
                SizedBox(
                  height: 238,
                  child: ListView.separated(
                    key: const ValueKey('free-lessons-list'),
                    scrollDirection: Axis.horizontal,
                    itemCount: freeLessons.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = LearnRepository.map(freeLessons[index]);
                      final uuid = _lessonUuid(item);
                      final bookmarked =
                          dashboard.bookmarked.contains(uuid) ||
                          LearnRepository.flag(item['bookmarked']);
                      return FreeLessonCard(
                        item: item,
                        bookmarked: bookmarked,
                        onTap: () => _openLessonFromItem(item),
                        onBookmark: () =>
                            _toggleBookmark(dashboard, uuid, bookmarked),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 23),
              LearningSectionHeader(
                icon: Icons.school_rounded,
                title: 'Featured Courses',
                action: 'All courses',
                onAction: () =>
                    _open(SubjectsScreen(repository: widget.repository)),
              ),
              const SizedBox(height: 10),
              if (featured.isEmpty)
                const LearningEmptyState(
                  title: 'No featured courses',
                  message: 'Featured published courses will appear here.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 720
                        ? math.min(520.0, constraints.maxWidth * .62)
                        : math.min(330.0, constraints.maxWidth * .9);
                    return SizedBox(
                      height: 310,
                      child: ListView.separated(
                        key: const ValueKey('featured-courses-list'),
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final course = LearnRepository.map(featured[index]);
                          return FeaturedCourseCard(
                            course: course,
                            width: cardWidth,
                            onTap: () => _open(
                              SubjectDetailsScreen(
                                repository: widget.repository,
                                courseUuid: LearnRepository.text(
                                  course['uuid'],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 18),
              LearningProgressCard(
                completed: LearnRepository.number(
                  learning['completed_lessons'],
                ),
                total: LearnRepository.number(
                  learning['accessible_published_lessons'],
                ),
                percent: LearnRepository.number(learning['completion_percent']),
                onTap: () => _open(
                  LearningProgressScreen(repository: widget.repository),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  List<LearningShortcutData> _shortcuts() => [
    LearningShortcutData(
      icon: Icons.school_outlined,
      title: 'Courses',
      subtitle: 'Structured learning paths',
      accent: learnGold,
      onTap: () => _open(SubjectsScreen(repository: widget.repository)),
    ),
    LearningShortcutData(
      icon: Icons.trending_up_rounded,
      title: 'Progress',
      subtitle: 'Track your growth',
      accent: learnGold,
      onTap: () => _open(LearningProgressScreen(repository: widget.repository)),
    ),
    LearningShortcutData(
      icon: Icons.assignment_outlined,
      title: 'Assignments',
      subtitle: 'Practice and apply',
      accent: learnGold,
      onTap: () => _open(AssignmentsScreen(repository: widget.repository)),
    ),
    LearningShortcutData(
      icon: Icons.auto_awesome_rounded,
      title: 'Ask to Trading BRAIN',
      subtitle: 'Get instant answers',
      accent: learnGold,
      onTap: () => _open(AskTradeXAiScreen(repository: widget.repository)),
    ),
    LearningShortcutData(
      icon: Icons.bookmark_border_rounded,
      title: 'Saved',
      subtitle: 'Your bookmarked content',
      accent: learnGold,
      onTap: () => _open(
        MyLearningScreen(repository: widget.repository, initialIndex: 3),
      ),
    ),
  ];

  void _openLessonFromItem(JsonMap item) {
    final uuid = _lessonUuid(item);
    if (uuid.isEmpty) return;
    _open(
      UniversalLessonViewerScreen(
        repository: widget.repository,
        lessonUuid: uuid,
      ),
    );
  }

  String _lessonUuid(JsonMap item) {
    final lesson = LearnRepository.map(item['lesson']);
    return LearnRepository.text(
      lesson['uuid'],
      LearnRepository.text(item['lesson_uuid']),
    );
  }

  Future<void> _resumeLearning(JsonMap item) async {
    final lessonUuid = _lessonUuid(item);
    final videoUuid = LearnRepository.text(item['last_video_uuid']);
    if (lessonUuid.isEmpty) return;
    if (videoUuid.isEmpty) {
      _openLessonFromItem(item);
      return;
    }
    setState(() => _resumingLessonUuid = lessonUuid);
    try {
      final token = await widget.repository.playbackToken(videoUuid);
      final playbackUrl = LearnRepository.text(token['playback_url']);
      if (playbackUrl.isEmpty) throw StateError('Playback URL unavailable');
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CourseVideoPlayerScreen(
            repository: widget.repository,
            lessonUuid: lessonUuid,
            videoUuid: videoUuid,
            title: LearnRepository.text(
              item['last_video_title'],
              LearnRepository.text(
                LearnRepository.map(item['lesson'])['title'],
                'TradeX course video',
              ),
            ),
            playbackUrl: playbackUrl,
            resumeSeconds: LearnRepository.number(
              item['last_position_seconds'],
            ),
          ),
        ),
      );
      if (mounted) await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This lesson video is temporarily unavailable.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resumingLessonUuid = null);
    }
  }

  Future<void> _toggleBookmark(
    _LearnDashboardData dashboard,
    String lessonUuid,
    bool bookmarked,
  ) async {
    if (lessonUuid.isEmpty) return;
    final next = !bookmarked;
    setState(() {
      if (next) {
        dashboard.bookmarked.add(lessonUuid);
      } else {
        dashboard.bookmarked.remove(lessonUuid);
      }
    });
    try {
      await widget.repository.setBookmark(lessonUuid, next);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (bookmarked) {
          dashboard.bookmarked.add(lessonUuid);
        } else {
          dashboard.bookmarked.remove(lessonUuid);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this bookmark.')),
      );
    }
  }
}

class _LearnDashboardData {
  const _LearnDashboardData({required this.overview, required this.bookmarked});

  final JsonMap overview;
  final Set<String> bookmarked;
}
