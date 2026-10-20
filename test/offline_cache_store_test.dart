import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/offline/offline_cache_store.dart';

void main() {
  late Directory directory;
  late OfflineCacheStore store;

  setUp(() async {
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
}
