part of '../home_dashboard_screen.dart';

class _ContinueLearningSection extends StatefulWidget {
  const _ContinueLearningSection({
    required this.repository,
    required this.onActionTap,
  });

  final DashboardLearningRepository repository;
  final ValueChanged<String> onActionTap;

  @override
  State<_ContinueLearningSection> createState() =>
      _ContinueLearningSectionState();
}

class _ContinueLearningSectionState extends State<_ContinueLearningSection> {
  late Future<HomeLearningData> _learning;

  @override
  void initState() {
    super.initState();
    _learning = widget.repository.loadHomeLearning();
  }

  @override
  Widget build(BuildContext context) => BlocFutureBuilder<HomeLearningData>(
    future: _learning,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 144,
          child: Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          ),
        );
      }

      final learning = snapshot.data;
      if (learning == null) {
        return _PremiumLockedLearningCard(
          onUnlock: () => widget.onActionTap('Premium Access'),
        );
      }

      if (learning.isPremium) {
        return _PremiumContinueLearningCard(
          item: learning.continueItem ?? learning.defaultPremiumItem,
          onTap: () => widget.onActionTap(
            learning.continueItem == null
                ? 'Start learning'
                : 'Continue learning',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PremiumLockedLearningCard(
            onUnlock: () => widget.onActionTap('Premium Access'),
          ),
          if (learning.freeLessons.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Free Lessons',
              style: TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            _FreeLearningHorizontalList(
              lessons: learning.freeLessons,
              onTap: (lesson) =>
                  widget.onActionTap('Free lesson: ${lesson.lessonTitle}'),
            ),
          ],
        ],
      );
    },
  );
}

class _PremiumLockedLearningCard extends StatelessWidget {
  const _PremiumLockedLearningCard({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _panelDecoration(context),
    child: Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Opacity(
              opacity: .46,
              child: IgnorePointer(
                child: _PremiumContinueLearningCard(
                  item: const LearningItem(
                    courseTitle: 'Premium Market Mastery',
                    moduleTitle: 'Advanced Market Structure',
                    lessonTitle: 'Institutional Trading Framework',
                    lessonUuid: '',
                    progressPercent: 68,
                    lastPositionSeconds: 0,
                    lastWatchedAt: null,
                    isFree: false,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                color: TradeXColors.goldBright,
                size: 30,
              ),
              const SizedBox(height: 7),
              const Text(
                'Premium content. Upgrade to continue learning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              _GoldButton(label: 'Unlock Premium', onTap: onUnlock),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PremiumContinueLearningCard extends StatelessWidget {
  const _PremiumContinueLearningCard({required this.item, required this.onTap});

  final LearningItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasHistory = item?.lastWatchedAt != null;
    final title = hasHistory
        ? item!.courseTitle
        : 'Start Your Learning Journey';
    final subtitle = item == null
        ? 'New premium lessons will appear here.'
        : '${item!.moduleTitle} · ${item!.lessonTitle}';
    final progress = (item?.progressPercent ?? 0).clamp(0, 100);

    return InkWell(
      onTap: item == null ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration(context),
        child: Row(
          children: [
            _CourseThumbnail(
              label: hasHistory ? 'CONTINUE\nLEARNING' : 'PREMIUM\nLEARNING',
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(99)),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      color: TradeXColors.goldBright,
                      backgroundColor: TradeXColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasHistory ? '$progress% complete' : 'Start learning',
                    style: const TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeLearningHorizontalList extends StatelessWidget {
  const _FreeLearningHorizontalList({
    required this.lessons,
    required this.onTap,
  });

  final List<LearningItem> lessons;
  final ValueChanged<LearningItem> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 130,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: lessons.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return SizedBox(
          width: 172,
          child: InkWell(
            onTap: () => onTap(lesson),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TradeXColors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TradeXColors.border),
              ),
              child: Row(
                children: [
                  _CourseThumbnail(label: 'FREE', compact: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TradeXColors.goldBright.withValues(
                              alpha: .16,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: TradeXColors.goldBright,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.lessonTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.moduleTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
