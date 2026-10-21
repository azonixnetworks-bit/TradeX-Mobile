import '../../../core/network/tradex_api_client.dart';
import '../../../core/preferences/app_preferences.dart';

typedef JsonMap = Map<String, dynamic>;

class LearnRepository {
  const LearnRepository(this._api);

  final TradeXApiClient _api;
  TradeXApiClient get apiClient => _api;

  Future<JsonMap> overview() => _data('/api/v1/education/overview');
  Future<JsonMap> languages() => _data('/api/v1/languages');

  Future<void> updateLanguage(String languageCode) async {
    await _api.patchJson('/api/v1/profile/preferences', {
      'language_code': languageCode.trim().toLowerCase(),
    });
    await AppPreferences.instance.setCourseLanguage(languageCode);
  }

  Future<JsonMap> courses({String search = '', String access = ''}) async {
    final params = <String, String>{
      if (access.isNotEmpty) 'access_level': access,
      'language_code': AppPreferences.instance.courseLanguage,
      'per_page': '50',
    };
    final payload = await _data(
      Uri(
        path: '/api/v1/education/courses',
        queryParameters: params,
      ).toString(),
    );
    if (search.trim().isEmpty) return payload;
    final query = search.toLowerCase();
    final items = list(payload['items'])
        .where((item) {
          final value = map(item);
          return text(value['title']).toLowerCase().contains(query) ||
              text(value['short_description']).toLowerCase().contains(query);
        })
        .toList(growable: false);
    return <String, dynamic>{...payload, 'items': items};
  }

  Future<JsonMap> course(String uuid) =>
      _data('/api/v1/education/courses/$uuid');
  Future<JsonMap> module(String uuid) =>
      _data('/api/v1/education/modules/$uuid');
  Future<JsonMap> lesson(String uuid) =>
      _data('/api/v1/education/lessons/$uuid');
  Future<JsonMap> myLearning(String view) => _data(
    '/api/v1/education/my-learning?view=${Uri.encodeQueryComponent(view)}&per_page=30',
  );
  Future<JsonMap> progress() => _data('/api/v1/education/progress');
  Future<JsonMap> products() => _data('/api/v1/products');
  Future<JsonMap> paymentActivationStatus() =>
      _data('/api/v1/payments/activation-status');
  Future<JsonMap> premiumAccess() async {
    final results = await Future.wait([products(), paymentActivationStatus()]);
    return {'products': results[0], 'activation': results[1]};
  }

  Future<JsonMap> assignments(String status) => _data(
    '/api/v1/education/assignments?status=${Uri.encodeQueryComponent(status)}&per_page=30',
  );
  Future<JsonMap> assignment(String uuid) =>
      _data('/api/v1/education/assignments/$uuid');

  Future<JsonMap> askAi(String question, {String? lessonUuid}) async {
    return _responseData(
      await _api.postJson('/api/v1/education/ai/ask', {
        'question': question,
        'lesson_uuid': ?lessonUuid,
      }),
    );
  }

  Future<void> updateProgress(
    String lessonUuid, {
    required String status,
    String? videoUuid,
    int positionSeconds = 0,
  }) async {
    await _api.patchJson('/api/v1/education/lessons/$lessonUuid/progress', {
      'status': status,
      'last_video_uuid': ?videoUuid,
      'last_position_seconds': positionSeconds,
    });
  }

  Future<void> setBookmark(String lessonUuid, bool bookmarked) async {
    final path = '/api/v1/education/lessons/$lessonUuid/bookmark';
    if (bookmarked) {
      await _api.putJson(path, const {});
    } else {
      await _api.deleteJson(path);
    }
  }

  Future<JsonMap> playbackToken(String videoUuid) async => _responseData(
    await _api.postJson(
      '/api/v1/education/videos/$videoUuid/playback-token',
      const {},
    ),
  );

  Future<JsonMap> whatsappAction(String assignmentUuid) async => _responseData(
    await _api.postJson(
      '/api/v1/education/assignments/$assignmentUuid/whatsapp-action',
      const {},
    ),
  );

  Future<JsonMap> _data(String path) async =>
      _responseData(await _api.getJson(path));

  JsonMap _responseData(JsonMap response) {
    final data = map(response['data']);
    final cache = response['_offline_cache'];
    if (cache is Map) data['_offline_cache'] = Map<String, dynamic>.from(cache);
    return data;
  }

  static JsonMap map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<dynamic> list(Object? value) => value is List ? value : const [];
  static String text(Object? value, [String fallback = '']) =>
      value?.toString().trim().isNotEmpty == true ? value.toString() : fallback;
  static int number(Object? value) => value is num ? value.toInt() : 0;
  static bool flag(Object? value) => value == true;
}
