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
