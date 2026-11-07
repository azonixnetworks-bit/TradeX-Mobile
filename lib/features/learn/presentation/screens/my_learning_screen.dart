part of '../learn_module.dart';

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
        _PremiumCard(
          child: TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: context.palette.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: context.palette.goldText,
            unselectedLabelColor: context.palette.secondaryText,
            tabs: const [
              Tab(text: 'Continue'),
              Tab(text: 'Recent'),
              Tab(text: 'Completed'),
              Tab(text: 'Saved'),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
