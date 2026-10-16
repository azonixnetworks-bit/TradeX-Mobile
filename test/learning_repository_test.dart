import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/home/data/learning_repository.dart';

void main() {
  group('HomeLearningData', () {
    test(
      'keeps non-premium learning locked and filters supplied free lessons',
      () {
        final learning = HomeLearningData.fromJson({
          'is_premium': false,
          'free_lessons': [_lesson('free-lesson', isFree: true)],
        });

        expect(learning.isPremium, isFalse);
        expect(learning.continueItem, isNull);
        expect(learning.freeLessons, hasLength(1));
        expect(learning.freeLessons.single.isFree, isTrue);
      },
    );

    test('uses the latest watched premium item and its saved progress', () {
      final learning = HomeLearningData.fromJson({
        'is_premium': true,
        'continue_learning': _lesson(
          'latest-lesson',
          progress: 64,
          watchedAt: '2026-10-16T10:30:00Z',
        ),
      });

      expect(learning.isPremium, isTrue);
      expect(learning.continueItem?.lessonUuid, 'latest-lesson');
      expect(learning.continueItem?.progressPercent, 64);
      expect(learning.continueItem?.lastWatchedAt, isNotNull);
    });

    test('supplies a first premium lesson when there is no watch history', () {
      final learning = HomeLearningData.fromJson({
        'is_premium': true,
        'default_premium_lesson': _lesson('first-premium'),
      });

      expect(learning.continueItem, isNull);
      expect(learning.defaultPremiumItem?.lessonUuid, 'first-premium');
    });
  });
}

Map<String, Object?> _lesson(
  String uuid, {
  bool isFree = false,
  int progress = 0,
  String? watchedAt,
}) => {
  'course': {'title': 'Smart Money', 'is_free': isFree},
  'module': {'title': 'Market Structure'},
  'lesson': {'uuid': uuid, 'title': 'Break of Structure'},
  'progress_percent': progress,
  'last_activity_at': watchedAt,
};
