import '../../../../core/network/api_exception.dart';
import '../../../../core/network/tradex_api_client.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../domain/repositories/learn_repository.dart';

import 'package:flutter/material.dart';

class LearnRepositoryImpl implements LearnRepository {
  const LearnRepositoryImpl(this._api);

  final TradeXApiClient _api;
  @override
  dynamic get paymentGateway => _api;
  @override
  String get courseLanguage => AppPreferences.instance.courseLanguage;

  @override
  bool get learnLanguageSelected =>
      AppPreferences.instance.learnLanguageSelected;

  @override
  String get themeModeName => AppPreferences.instance.state.themeMode.name;

  @override
  Future<void> setThemeModeName(String value) =>
      AppPreferences.instance.setThemeMode(
        value == 'light'
            ? ThemeMode.light
            : value == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system,
      );

  @override
  Future<JsonMap> overview() async {
    try {
      return await _data('/api/v1/education/overview');
    } on ApiException catch (error) {
      if ((error.statusCode ?? 0) < 500) rethrow;

      // The home dashboard already carries the same learning summary. Keep the
      // Learn tab usable when the dedicated overview endpoint is temporarily
      // unavailable, without masking authentication or connectivity failures.
      final dashboard = await _data('/api/v1/dashboard');
      final learning = map(dashboard['learning']);
      if (learning.isEmpty) rethrow;

      return <String, dynamic>{
        'is_premium': learning['is_premium'] ?? dashboard['is_premium'],
        'learning': learning,
        'featured_courses': list(
          dashboard['featured_courses'] ?? learning['featured_courses'],
        ),
      };
    }
  }

  @override
  Future<JsonMap> languages() => _data('/api/v1/languages');

  @override
  Future<void> updateLanguage(String languageCode) async {
    await _api.patchJson('/api/v1/profile/preferences', {
      'language_code': languageCode.trim().toLowerCase(),
    });
    await AppPreferences.instance.setCourseLanguage(languageCode);
  }

  @override
  Future<JsonMap> courses({String search = '', String access = ''}) async {
    final params = <String, String>{
      if (access.isNotEmpty) 'access_level': access,
      'language_code': courseLanguage,
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

  @override
  Future<JsonMap> course(String uuid) async {
    final path = '/api/v1/education/courses/$uuid';
    final localizedPath = Uri(
      path: path,
      queryParameters: {'language_code': courseLanguage},
    ).toString();
    try {
      return await _data(localizedPath);
    } on ApiException catch (error) {
      // Some deployed education API versions do not accept language_code on
      // the course-detail route. Retry the canonical route only for a server
      // failure; auth, access and not-found responses must keep their meaning.
      if ((error.statusCode ?? 0) < 500) rethrow;
      return _data(path);
    }
  }

  @override
  Future<JsonMap> module(String uuid) =>
      _data('/api/v1/education/modules/$uuid');
  @override
  Future<JsonMap> lesson(String uuid) =>
      _data('/api/v1/education/lessons/$uuid');
  @override
  Future<JsonMap> myLearning(String view) => _data(
    '/api/v1/education/my-learning?view=${Uri.encodeQueryComponent(view)}&per_page=30',
  );
  @override
  Future<JsonMap> progress() => _data('/api/v1/education/progress');
  @override
  Future<JsonMap> products() => _data('/api/v1/products');
  @override
  Future<JsonMap> paymentActivationStatus() =>
      _data('/api/v1/payments/activation-status');
  @override
  Future<JsonMap> premiumAccess() async {
    final results = await Future.wait([products(), paymentActivationStatus()]);
    return {'products': results[0], 'activation': results[1]};
  }

  @override
  Future<JsonMap> assignments(String status) => _data(
    '/api/v1/education/assignments?status=${Uri.encodeQueryComponent(status)}&per_page=30',
  );
  @override
  Future<JsonMap> assignment(String uuid) =>
      _data('/api/v1/education/assignments/$uuid');

  @override
  Future<JsonMap> askAi(String question, {String? lessonUuid}) async {
    return _responseData(
      await _api.postJson('/api/v1/education/ai/ask', {
        'question': question,
        'lesson_uuid': ?lessonUuid,
      }),
    );
  }

  @override
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

  @override
  Future<void> setBookmark(String lessonUuid, bool bookmarked) async {
    final path = '/api/v1/education/lessons/$lessonUuid/bookmark';
    if (bookmarked) {
      await _api.putJson(path, const {});
    } else {
      await _api.deleteJson(path);
    }
  }

  @override
  Future<JsonMap> playbackToken(String videoUuid) async => _responseData(
    await _api.postJson(
      '/api/v1/education/videos/$videoUuid/playback-token',
      const {},
    ),
  );

  @override
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

  static JsonMap map(Object? value) => LearnRepository.map(value);
  static List<dynamic> list(Object? value) => LearnRepository.list(value);
  static String text(Object? value, [String fallback = '']) =>
      LearnRepository.text(value, fallback);
  static int number(Object? value) => LearnRepository.number(value);
  static bool flag(Object? value) => LearnRepository.flag(value);
}
