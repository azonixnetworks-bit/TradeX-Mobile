import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/api_exception.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_colors.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/learn/data/learn_repository.dart';
import 'package:tradex_mobile/features/learn/presentation/course_video_player_screen.dart';
import 'package:tradex_mobile/features/learn/presentation/learn_dashboard_widgets.dart';
import 'package:tradex_mobile/features/learn/presentation/learn_module.dart';
import 'package:tradex_mobile/features/catalog/presentation/secure_workflow_screens.dart';

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
    final featuredList = find.byKey(const ValueKey('featured-courses-list'));
    final featuredCard = find.byKey(
      const ValueKey('featured-course-course-featured'),
    );
    expect(
      tester.getSize(featuredCard).width,
      closeTo(tester.getSize(featuredList).width, .01),
    );
    expect(find.text('35%'), findsOneWidget);
    expect(find.text('7 of 20 lessons completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium access shows one secure customer-facing product card', (
    tester,
  ) async {
    const productUuid = '123e4567-e89b-42d3-a456-426614174000';
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: PremiumAccessScreen(
          repository: LearnRepository(_PremiumProductsLearnApiClient()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TradeX Education Premium'), findsOneWidget);
    expect(find.text('Subscribe securely'), findsOneWidget);
    expect(find.text('Premium lessons'), findsOneWidget);
    expect(find.text(productUuid), findsNothing);
    expect(find.textContaining('EDUCATION_PREMIUM'), findsNothing);
    expect(find.text('Unrelated Product'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('education-premium-product-card')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaymentCheckoutScreen), findsOneWidget);
    expect(find.text(productUuid), findsNothing);
  });

  testWidgets('course description uses readable global text and expands', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: SubjectDetailsScreen(
          repository: LearnRepository(_CourseDetailsApiClient()),
          courseUuid: 'course-featured',
        ),
      ),
    );
    await tester.pumpAndSettle();

    var description = tester.widget<Text>(
      find.byKey(const ValueKey('course-description-text')),
    );
    expect(description.maxLines, 4);
    expect(description.style?.color, isNot(TradeXColors.secondaryText));
    expect(find.text('Read more'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('course-continue-learning')),
      findsOneWidget,
    );
    expect(find.text('2 Modules'), findsOneWidget);
    expect(find.text('3 Lessons'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('course-description-toggle')));
    await tester.pumpAndSettle();
    description = tester.widget<Text>(
      find.byKey(const ValueKey('course-description-text')),
    );
    expect(description.maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);

    final curriculumButton = find.byKey(
      const ValueKey('open-course-curriculum'),
    );
    for (
      var attempt = 0;
      attempt < 5 && curriculumButton.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -280));
      await tester.pumpAndSettle();
    }
    expect(curriculumButton, findsOneWidget);
    await tester.ensureVisible(curriculumButton);
    await tester.tap(curriculumButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('course-curriculum-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('curriculum-module-module-one')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('curriculum-lesson-lesson-last')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('curriculum-lesson-lesson-last')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(UniversalLessonViewerScreen), findsOneWidget);
  });

  testWidgets('curriculum preserves empty and locked access states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LearnRepository(_CourseDetailsApiClient());

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CourseCurriculumScreen(
          key: const ValueKey('protected-curriculum'),
          repository: repository,
          course: const <String, dynamic>{
            'title': 'Empty Course',
            'progress': <String, dynamic>{
              'total_lessons': 0,
              'completed_lessons': 0,
              'percent': 0,
            },
          },
          modules: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No modules are available for this course yet.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('curriculum-continue-learning')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CourseCurriculumScreen(
          key: const ValueKey('locked-curriculum'),
          repository: repository,
          course: const <String, dynamic>{
            'title': 'Protected Course',
            'progress': <String, dynamic>{
              'total_lessons': 1,
              'completed_lessons': 0,
              'percent': 0,
            },
          },
          modules: const [
            <String, dynamic>{
              'uuid': 'protected-module',
              'title': 'Protected Module',
              'lesson_count': 1,
              'lessons': [
                <String, dynamic>{
                  'uuid': 'protected-lesson',
                  'title': 'Premium Lesson',
                  'is_locked': true,
                  'progress': <String, dynamic>{'status': 'NOT_STARTED'},
                },
              ],
            },
          ],
          initialModuleUuid: 'protected-module',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final protectedLesson = find.byKey(
      const ValueKey('curriculum-lesson-protected-lesson'),
    );
    for (
      var attempt = 0;
      attempt < 4 && protectedLesson.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(
        find.byKey(const ValueKey('course-curriculum-list')),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
    }
    expect(protectedLesson, findsOneWidget);
    await tester.ensureVisible(protectedLesson);
    await tester.tap(protectedLesson);
    await tester.pumpAndSettle();
    expect(find.byType(PremiumAccessScreen), findsOneWidget);
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

  testWidgets('continue does not depend on the lesson-detail endpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _LessonDetailFailureLearnApiClient();

    await tester.pumpWidget(_subject(api));
    await tester.pumpAndSettle();
    final continueButton = find.byKey(
      const ValueKey('continue-learning-button'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(api.lessonDetailRequests, 0);
    expect(
      api.postedPaths,
      contains('/api/v1/education/videos/video-last/playback-token'),
    );
    expect(find.byType(CourseVideoPlayerScreen), findsOneWidget);
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
    for (
      var attempt = 0;
      attempt < 6 && bookmark.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -320));
      await tester.pumpAndSettle();
    }
    expect(bookmark, findsOneWidget);
    await tester.ensureVisible(bookmark);
    await tester.pumpAndSettle();
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

class _CourseDetailsApiClient extends _LearnApiClient {
  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/education/courses/course-featured') {
      return {
        'data': {
          'course': {
            ..._LearnApiClient._featuredCourse(),
            'description': List.filled(
              12,
              'Learn market structure, risk control and disciplined execution.',
            ).join(' '),
            'progress': {
              'total_lessons': 3,
              'completed_lessons': 1,
              'percent': 33,
            },
          },
          'modules': [
            {
              'uuid': 'module-one',
              'title': 'How Market Works',
              'lesson_count': 2,
              'lessons': [
                {
                  'uuid': 'lesson-complete',
                  'title': 'What is Market Mechanics?',
                  'is_locked': false,
                  'progress': {'status': 'COMPLETED'},
                },
                {
                  'uuid': 'lesson-last',
                  'title': 'Supply and Demand',
                  'is_locked': false,
                  'progress': {'status': 'IN_PROGRESS'},
                },
              ],
            },
            {
              'uuid': 'module-two',
              'title': 'Market Trends',
              'lesson_count': 1,
              'lessons': [
                {
                  'uuid': 'lesson-locked',
                  'title': 'Trend Continuation',
                  'is_locked': true,
                  'progress': {'status': 'NOT_STARTED'},
                },
              ],
            },
          ],
        },
      };
    }
    return super.getJson(path);
  }
}

class _LessonDetailFailureLearnApiClient extends _LearnApiClient {
  int lessonDetailRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/education/lessons/')) {
      lessonDetailRequests += 1;
      throw const ApiException(message: 'Server Error', statusCode: 500);
    }
    return super.getJson(path);
  }
}

class _PremiumProductsLearnApiClient extends _LearnApiClient {
  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/api/v1/products') {
      return const {
        'data': {
          'items': [
            {
              'uuid': 'unrelated-uuid',
              'code': 'OTHER_PRODUCT',
              'name': 'Unrelated Product',
            },
            {
              'uuid': '123e4567-e89b-42d3-a456-426614174000',
              'code': 'EDUCATION_PREMIUM',
              'name': 'TradeX Education Premium',
              'description': 'Premium trading education and course access.',
              'price': {'currency': 'USD', 'amount': '79.00'},
            },
          ],
        },
      };
    }
    if (path == '/api/v1/payments/activation-status') {
      return const {
        'data': {'premium_active': false, 'status': 'INACTIVE'},
      };
    }
    return super.getJson(path);
  }
}
