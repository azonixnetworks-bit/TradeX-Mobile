import '../../../core/network/tradex_api_client.dart';
import '../domain/learning_repository.dart';

export '../domain/learning_repository.dart';

class LearningRepository implements DashboardLearningRepository {
  const LearningRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  @override
  Future<HomeLearningData> loadHomeLearning() async {
    final response = await _apiClient.getJson('/api/v1/dashboard');
    final data = response['data'];
    final learning = data is Map ? data['learning'] : null;
    return homeLearningDataFromJson(
      learning is Map ? Map<String, dynamic>.from(learning) : const {},
    );
  }
}

HomeLearningData homeLearningDataFromJson(Map<String, dynamic> json) {
  LearningItem? parseItem(Object? value) => value is Map
      ? _learningItemFromJson(Map<String, dynamic>.from(value))
      : null;

  return HomeLearningData(
    isPremium: json['is_premium'] == true,
    continueItem: parseItem(json['continue_learning']),
    defaultPremiumItem: parseItem(json['default_premium_lesson']),
    freeLessons: (json['free_lessons'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _learningItemFromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false),
  );
}

LearningItem _learningItemFromJson(Map<String, dynamic> json) {
  final course = json['course'] is Map
      ? Map<String, dynamic>.from(json['course'] as Map)
      : const <String, dynamic>{};
  final module = json['module'] is Map
      ? Map<String, dynamic>.from(json['module'] as Map)
      : const <String, dynamic>{};
  final lesson = json['lesson'] is Map
      ? Map<String, dynamic>.from(json['lesson'] as Map)
      : const <String, dynamic>{};
  final watchedAt = json['last_activity_at']?.toString();
  return LearningItem(
    courseTitle: course['title']?.toString() ?? 'TradeX Learning',
    moduleTitle: module['title']?.toString() ?? 'Learning module',
    lessonTitle: lesson['title']?.toString() ?? 'Start your next lesson',
    lessonUuid: lesson['uuid']?.toString() ?? '',
    progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
    lastPositionSeconds: (json['last_position_seconds'] as num?)?.toInt() ?? 0,
    lastWatchedAt: watchedAt == null ? null : DateTime.tryParse(watchedAt),
    isFree: course['is_free'] == true,
  );
}
