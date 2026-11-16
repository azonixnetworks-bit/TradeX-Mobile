class HomeLearningData {
  const HomeLearningData({
    required this.isPremium,
    required this.continueItem,
    required this.defaultPremiumItem,
    required this.freeLessons,
  });

  final bool isPremium;
  final LearningItem? continueItem;
  final LearningItem? defaultPremiumItem;
  final List<LearningItem> freeLessons;
}

class LearningItem {
  const LearningItem({
    required this.courseUuid,
    required this.courseTitle,
    required this.moduleTitle,
    required this.lessonTitle,
    required this.lessonUuid,
    required this.progressPercent,
    required this.lastPositionSeconds,
    required this.lastWatchedAt,
    required this.isFree,
  });

  final String courseUuid;
  final String courseTitle;
  final String moduleTitle;
  final String lessonTitle;
  final String lessonUuid;
  final int progressPercent;
  final int lastPositionSeconds;
  final DateTime? lastWatchedAt;
  final bool isFree;
}

abstract interface class DashboardLearningRepository {
  Future<HomeLearningData> loadHomeLearning();
}
