part of '../learn_module.dart';

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
    title: 'All Courses',
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
    title: 'Course Details',
    child: _FutureBody(
      future: repository.course(courseUuid),
      builder: (data) {
        final course = LearnRepository.map(data['course']);
        final modules = LearnRepository.list(data['modules']);
        final continueLesson = _courseContinueLesson(modules);
        return ListView(
          children: [
            _CourseHero(course: course, modules: modules),
            if (continueLesson.isNotEmpty) ...[
              const SizedBox(height: 14),
              _CourseContinueCard(
                lesson: continueLesson,
                progress: LearnRepository.map(course['progress']),
                onTap: () =>
                    _openCourseLesson(context, repository, continueLesson),
              ),
            ],
            const SizedBox(height: 18),
            const _SectionHeading(
              icon: Icons.layers_outlined,
              title: 'Course Curriculum',
            ),
            const SizedBox(height: 10),
            if (modules.isEmpty) const _EmptyState('No modules available yet.'),
            ...modules.indexed.map((entry) {
              final index = entry.$1;
              final raw = entry.$2;
              final module = LearnRepository.map(raw);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CourseModulePreviewCard(
                  index: index,
                  module: module,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CourseCurriculumScreen(
                        repository: repository,
                        course: course,
                        modules: modules,
                        initialModuleUuid: LearnRepository.text(module['uuid']),
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (modules.isNotEmpty) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                key: const ValueKey('open-course-curriculum'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CourseCurriculumScreen(
                      repository: repository,
                      course: course,
                      modules: modules,
                    ),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('View Full Curriculum'),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class CourseCurriculumScreen extends StatefulWidget {
  const CourseCurriculumScreen({
    super.key,
    required this.repository,
    required this.course,
    required this.modules,
    this.initialModuleUuid,
  });

  final LearnRepository repository;
  final JsonMap course;
  final List<dynamic> modules;
  final String? initialModuleUuid;

  @override
  State<CourseCurriculumScreen> createState() => _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState extends State<CourseCurriculumScreen> {
  String? _expandedModule;

  @override
  void initState() {
    super.initState();
    final requested = widget.initialModuleUuid?.trim() ?? '';
    if (requested.isNotEmpty) {
      _expandedModule = requested;
    } else {
      _expandedModule = _moduleWithInProgressLesson(widget.modules);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.modules.map(LearnRepository.map).toList();
    final continueLesson = _courseContinueLesson(widget.modules);
    return _LearnScaffold(
      title: 'Curriculum',
      child: ListView(
        key: const ValueKey('course-curriculum-list'),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _CurriculumSummaryCard(
            course: widget.course,
            modules: widget.modules,
          ),
          const SizedBox(height: 14),
          if (modules.isEmpty)
            const _EmptyState('No modules are available for this course yet.')
          else
            ...modules.indexed.map((entry) {
              final module = entry.$2;
              final uuid = LearnRepository.text(module['uuid']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CurriculumModuleCard(
                  index: entry.$1,
                  module: module,
                  expanded: uuid == _expandedModule,
                  onToggle: () => setState(
                    () =>
                        _expandedModule = _expandedModule == uuid ? null : uuid,
                  ),
                  onLessonTap: (lesson) =>
                      _openCourseLesson(context, widget.repository, lesson),
                ),
              );
            }),
          if (continueLesson.isNotEmpty) ...[
            const SizedBox(height: 6),
            FilledButton.icon(
              key: const ValueKey('curriculum-continue-learning'),
              onPressed: () =>
                  _openCourseLesson(context, widget.repository, continueLesson),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Continue Learning'),
            ),
          ],
        ],
      ),
    );
  }
}

void _openCourseLesson(
  BuildContext context,
  LearnRepository repository,
  JsonMap lesson,
) {
  if (LearnRepository.flag(lesson['is_locked'])) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PremiumAccessScreen(repository: repository),
      ),
    );
    return;
  }
  final uuid = LearnRepository.text(lesson['uuid']);
  if (uuid.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          UniversalLessonViewerScreen(repository: repository, lessonUuid: uuid),
    ),
  );
}

JsonMap _courseContinueLesson(List<dynamic> modules) {
  for (final rawModule in modules) {
    final module = LearnRepository.map(rawModule);
    for (final rawLesson in LearnRepository.list(module['lessons'])) {
      final lesson = LearnRepository.map(rawLesson);
      final progress = LearnRepository.map(lesson['progress']);
      if (LearnRepository.text(progress['status']).toUpperCase() ==
              'IN_PROGRESS' &&
          LearnRepository.text(lesson['uuid']).isNotEmpty &&
          !LearnRepository.flag(lesson['is_locked'])) {
        return lesson;
      }
    }
  }
  return const <String, dynamic>{};
}

String? _moduleWithInProgressLesson(List<dynamic> modules) {
  for (final rawModule in modules) {
    final module = LearnRepository.map(rawModule);
    for (final rawLesson in LearnRepository.list(module['lessons'])) {
      final progress = LearnRepository.map(
        LearnRepository.map(rawLesson)['progress'],
      );
      if (LearnRepository.text(progress['status']).toUpperCase() ==
          'IN_PROGRESS') {
        return LearnRepository.text(module['uuid']);
      }
    }
  }
  return null;
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
        final progress = LearnRepository.map(module['progress']);
        return ListView(
          children: [
            if (_thumbnailValue(module).isNotEmpty) ...[
              CourseThumbnail(
                thumbnailPath: _thumbnailValue(module),
                height: 180,
              ),
              const SizedBox(height: 14),
            ],
            _InfoCard(
              title: LearnRepository.text(module['title'], 'Module'),
              body: LearnRepository.text(
                module['description'],
                LearnRepository.text(module['short_description']),
              ),
            ),
            if (progress.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ProgressSummary(
                completed: LearnRepository.number(
                  progress['completed_lessons'],
                ),
                total: LearnRepository.number(
                  progress['total_lessons'] ?? module['lesson_count'],
                ),
                percent: LearnRepository.number(progress['percent']),
              ),
            ],
            const SizedBox(height: 14),
            const _SectionHeading(
              icon: Icons.play_lesson_outlined,
              title: 'Lessons',
            ),
            const SizedBox(height: 10),
            if (lessons.isEmpty) const _EmptyState('No lessons available yet.'),
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
