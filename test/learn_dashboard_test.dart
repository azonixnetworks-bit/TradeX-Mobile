import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/api_exception.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/learn/data/learn_repository.dart';
import 'package:tradex_mobile/features/learn/presentation/course_video_player_screen.dart';
import 'package:tradex_mobile/features/learn/presentation/learn_dashboard_widgets.dart';
import 'package:tradex_mobile/features/learn/presentation/learn_module.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'tradex.course_language': 'en',
      'tradex.learn_language_selected': true,
    });
    await AppPreferences.instance.load();
  });

  testWidgets('premium learn dashboard renders authenticated API data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _LearnApiClient();

    await tester.pumpWidget(_subject(api));
    await tester.pumpAndSettle();

    expect(find.text('Learn.'), findsOneWidget);
    expect(find.text('Market Structure Mastery'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    for (final label in const [
      'Courses',
      'Progress',
      'Assignments',
      'Ask to Trading BRAIN',
      'Saved',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Settings'), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('overall-learning-progress')),
      450,
      scrollable: scrollable,
    );
    expect(find.text('Free Price Action Lesson'), findsOneWidget);
    expect(find.text('Featured Trading Course'), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
    expect(find.text('7 of 20 lessons completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('learn dashboard falls back when overview service returns 500', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _OverviewFailureLearnApiClient();

    await tester.pumpWidget(_subject(api));
    await tester.pumpAndSettle();

    expect(api.requestedPaths, [
      '/api/v1/education/overview',
      '/api/v1/dashboard',
      '/api/v1/education/my-learning?view=SAVED&per_page=30',
    ]);
    expect(find.text('Learn.'), findsOneWidget);
    expect(find.text('Market Structure Mastery'), findsOneWidget);
    expect(find.text('Server Error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('continue resumes exact last watched video and saved position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _LearnApiClient();

    await tester.pumpWidget(_subject(api));
    await tester.pumpAndSettle();
    final continueButton = find.byKey(
      const ValueKey('continue-learning-button'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(
      api.postedPaths,
      contains('/api/v1/education/videos/video-last/playback-token'),
    );
    expect(find.byType(CourseVideoPlayerScreen), findsOneWidget);
    final player = tester.widget<CourseVideoPlayerScreen>(
      find.byType(CourseVideoPlayerScreen),
    );
    expect(player.lessonUuid, 'lesson-last');
    expect(player.videoUuid, 'video-last');
    expect(player.resumeSeconds, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free lesson bookmark uses existing user-scoped API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _LearnApiClient();

    await tester.pumpWidget(_subject(api));
    await tester.pumpAndSettle();
    final bookmark = find.byKey(const ValueKey('bookmark-lesson-free'));
    await tester.scrollUntilVisible(
      bookmark,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(bookmark);
    await tester.pump();

    expect(
      api.deletedPaths,
      contains('/api/v1/education/lessons/lesson-free/bookmark'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('learn dashboard has no overflow at 320 pixels', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _LearnApiClient();

    await tester.pumpWidget(_subject(api));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('learn-dashboard-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final position = scrollable.position;
    for (final fraction in const [.2, .4, .6, .8, 1.0]) {
      position.jumpTo(position.maxScrollExtent * fraction);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('every subject course card renders its backend thumbnail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_subject(_LearnApiClient()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();

    final thumbnail = tester.widget<CourseThumbnail>(
      find.byKey(const ValueKey('course-thumbnail-course-featured')),
    );
    expect(
      thumbnail.thumbnailPath,
      'education/courses/featured-trading/thumbnail.webp',
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _subject(_LearnApiClient api) => MaterialApp(
  theme: TradeXTheme.dark,
  home: Scaffold(body: LearnHomeScreen(repository: LearnRepository(api))),
);

class _LearnApiClient extends TradeXApiClient {
  _LearnApiClient()
    : super(SecureSessionStore(), DeviceIdentity(SecureSessionStore()));

  final postedPaths = <String>[];
  final deletedPaths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/education/overview') {
      return {'data': _overview()};
    }
    if (path.startsWith('/api/v1/education/my-learning?')) {
      return {
        'data': {
          'items': [
            {
              'lesson': {'uuid': 'lesson-free'},
              'bookmarked': true,
            },
          ],
        },
      };
    }
    if (path == '/api/v1/education/lessons/lesson-last') {
      return {
        'data': {
          'lesson': {
            'uuid': 'lesson-last',
            'title': 'Market Structure Mastery',
          },
          'videos': [
            {
              'uuid': 'video-last',
              'title': 'Break of Structure',
              'duration_seconds': 70,
              'playback_ready': true,
            },
          ],
        },
      };
    }
    if (path.startsWith('/api/v1/education/courses')) {
      return {
        'data': {
          'items': [_featuredCourse()],
        },
      };
    }
    if (path.startsWith('/api/v1/education/progress')) {
      return {
        'data': {
          'overall': {
            'total_lessons': 20,
            'completed_lessons': 7,
            'in_progress_lessons': 1,
            'percent': 35,
          },
          'courses': [_featuredCourse()],
          'recent_completions': const [],
        },
      };
    }
    return const {'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    postedPaths.add(path);
    if (path.endsWith('/playback-token')) {
      return {
        'data': {'playback_url': 'https://example.test/protected.m3u8'},
      };
    }
    return const {'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async => const {'data': <String, dynamic>{}};

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    deletedPaths.add(path);
    return const {'data': <String, dynamic>{}};
  }

  static Map<String, dynamic> _overview() => {
    'is_premium': true,
    'learning': {
      'accessible_published_lessons': 20,
      'completed_lessons': 7,
      'in_progress_lessons': 1,
      'completion_percent': 35,
      'continue_learning': {
        'course': {
          'uuid': 'course-featured',
          'title': 'Featured Trading Course',
        },
        'module': {'uuid': 'module-1', 'title': 'Market Structure'},
        'lesson': {'uuid': 'lesson-last', 'title': 'Market Structure Mastery'},
        'status': 'IN_PROGRESS',
        'last_video_uuid': 'video-last',
        'last_position_seconds': 42,
        'last_activity_at': '2026-10-24T10:00:00Z',
        'progress_percent': 60,
      },
      'default_premium_lesson': null,
      'free_lessons': [
        {
          'course': {
            'uuid': 'course-free',
            'title': 'Free Trading Basics',
            'is_free': true,
          },
          'module': {'uuid': 'module-free', 'title': 'Price Action'},
          'lesson': {
            'uuid': 'lesson-free',
            'title': 'Free Price Action Lesson',
          },
          'duration_seconds': 495,
        },
      ],
    },
    'featured_courses': [_featuredCourse()],
    'assignment_summary': {'available': 2},
  };

  static Map<String, dynamic> _featuredCourse() => {
    'uuid': 'course-featured',
    'title': 'Featured Trading Course',
    'short_description': 'Professional market structure and risk management.',
    'thumbnail_path': 'education/courses/featured-trading/thumbnail.webp',
    'access_level': 'PREMIUM',
    'is_featured': true,
    'is_locked': false,
    'progress': {'total_lessons': 24, 'completed_lessons': 6, 'percent': 25},
  };
}

class _OverviewFailureLearnApiClient extends _LearnApiClient {
  final requestedPaths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    requestedPaths.add(path);
    if (path == '/api/v1/education/overview') {
      throw const ApiException(message: 'Server Error', statusCode: 500);
    }
    if (path == '/api/v1/dashboard') {
      final overview = _LearnApiClient._overview();
      return {
        'data': {
          'learning': overview['learning'],
          'is_premium': overview['is_premium'],
          'featured_courses': overview['featured_courses'],
        },
      };
    }
    return super.getJson(path);
  }
}
