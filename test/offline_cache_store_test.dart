import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/auth_session.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/offline/offline_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late OfflineCacheStore store;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('tradex-offline-test-');
    store = OfflineCacheStore(directoryProvider: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('cached API data remains isolated per account', () async {
    await store.put(
      accountKey: 'uuid:user-a',
      requestKey: '/api/v1/education/overview',
      payload: const {
        'data': {'course_count': 3},
      },
      maxAge: const Duration(hours: 1),
    );

    final owner = await store.get(
      accountKey: 'uuid:user-a',
      requestKey: '/api/v1/education/overview',
    );
    final other = await store.get(
      accountKey: 'uuid:user-b',
      requestKey: '/api/v1/education/overview',
    );

    expect(owner?.payload['data'], {'course_count': 3});
    expect(owner?.isExpired, isFalse);
    expect(other, isNull);
  });

  test('safe offline edits use last-write-wins deduplication', () async {
    const path = '/api/v1/education/lessons/lesson-1/progress';
    await store.enqueue(
      accountKey: 'uuid:user-a',
      method: 'PATCH',
      path: path,
      body: const {'last_position_seconds': 15},
    );
    await store.enqueue(
      accountKey: 'uuid:user-a',
      method: 'PATCH',
      path: path,
      body: const {'last_position_seconds': 42},
    );

    final queued = await store.queued('uuid:user-a');
    expect(queued, hasLength(1));
    expect(queued.single.body?['last_position_seconds'], 42);

    await store.removeQueued('uuid:user-a', queued.single.key);
    expect(await store.queued('uuid:user-a'), isEmpty);
  });

  test('clearing one account removes its cache and pending edits', () async {
    await store.put(
      accountKey: 'uuid:user-a',
      requestKey: '/api/v1/products',
      payload: const {'data': {}},
      maxAge: const Duration(days: 1),
    );
    await store.enqueue(
      accountKey: 'uuid:user-a',
      method: 'PUT',
      path: '/api/v1/education/lessons/lesson-1/bookmark',
    );

    await store.clearAccount('uuid:user-a');

    expect(
      await store.get(
        accountKey: 'uuid:user-a',
        requestKey: '/api/v1/products',
      ),
      isNull,
    );
    expect(await store.queued('uuid:user-a'), isEmpty);
  });

  test(
    'cache-first GET restores trade journal without a network request',
    () async {
      const storage = FlutterSecureStorage();
      final sessionStore = SecureSessionStore(storage: storage);
      final now = DateTime.now().toUtc();
      await sessionStore.writeSession(
        AuthSession(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessExpiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          sessionUuid: 'session-a',
          user: const {'uuid': 'user-a'},
        ),
      );
      const path = '/api/v1/trade-journal/home?timezone=Asia%2FColombo';
      await store.put(
        accountKey: 'uuid:user-a',
        requestKey: path,
        payload: const {
          'data': {'timezone': 'Asia/Colombo', 'recent': <Object>[]},
        },
        maxAge: const Duration(hours: 24),
      );
      final client = TradeXApiClient(
        sessionStore,
        DeviceIdentity(sessionStore),
        offlineStore: store,
      );

      final response = await client.getJsonCacheFirst(path);

      expect((response['data'] as Map)['timezone'], 'Asia/Colombo');
      expect((response['_offline_cache'] as Map)['cache_first'], isTrue);
    },
  );

  test(
    'trade journal loads server once and then reads its local copy',
    () async {
      const storage = FlutterSecureStorage();
      final sessionStore = SecureSessionStore(storage: storage);
      final now = DateTime.now().toUtc();
      await sessionStore.writeSession(
        AuthSession(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessExpiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          sessionUuid: 'session-a',
          user: const {'uuid': 'user-a'},
        ),
      );
      var networkCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            networkCalls++;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'data': {'timezone': 'Asia/Colombo'},
                },
              ),
            );
          },
        ),
      );
      final client = TradeXApiClient(
        sessionStore,
        DeviceIdentity(sessionStore),
        dio: dio,
        offlineStore: store,
      );
      const path = '/api/v1/trade-journal/home?timezone=Asia%2FColombo';

      final first = await client.getJsonCacheFirst(path);
      final second = await client.getJsonCacheFirst(path);

      expect((first['data'] as Map)['timezone'], 'Asia/Colombo');
      expect((second['_offline_cache'] as Map)['cache_first'], isTrue);
      expect(networkCalls, 1);
    },
  );
}
