import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final modules = <String>['auth', 'profile', 'catalog', 'secure_workflows'];

  group('phase 3 strict clean architecture', () {
    for (final module in modules) {
      test('$module domain is pure Dart', () {
        final directory = Directory('lib/features/$module/domain');
        expect(directory.existsSync(), isTrue);
        final content = _dart(directory)
            .map((file) => file.readAsStringSync())
            .join('\n');
        for (final forbidden in <String>[
          'package:flutter/',
          '/data/',
          '/presentation/',
          'tradex_api_client.dart',
          'shared_preferences',
          'flutter_secure_storage',
          'local_auth',
          'image_picker',
          'url_launcher',
          'flutter_timezone',
        ]) {
          expect(
            content,
            isNot(contains(forbidden)),
            reason: '$module domain contains $forbidden',
          );
        }
      });

      test('$module data never imports presentation', () {
        final directory = Directory('lib/features/$module/data');
        expect(directory.existsSync(), isTrue);
        final content = _dart(directory)
            .map((file) => file.readAsStringSync())
            .join('\n');
        expect(content, isNot(contains('/presentation/')));
      });
    }

    test('scoped presentation has no concrete infrastructure imports', () {
      final files = <File>[
        ..._dart(Directory('lib/features/auth/presentation')),
        ..._dart(Directory('lib/features/profile/presentation')),
        ..._dart(Directory('lib/features/catalog/presentation')),
      ];
      final content = files.map((file) => file.readAsStringSync()).join('\n');
      for (final forbidden in <String>[
        '/data/',
        'core/network/',
        'tradex_api_client.dart',
        'shared_preferences',
        'flutter_secure_storage',
        'local_auth',
        'image_picker',
        'url_launcher',
        'flutter_timezone',
      ]) {
        expect(
          content,
          isNot(contains(forbidden)),
          reason: 'presentation contains $forbidden',
        );
      }
    });

    test('catalog presentation does not construct feature repositories', () {
      final content = _dart(Directory('lib/features/catalog/presentation'))
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(
        content,
        isNot(matches(RegExp(r'(Repository|Dependencies)\s*\('))),
      );
    });

    test('scoped presentation has no cross-feature data imports', () {
      final content = <String>['auth', 'profile', 'catalog']
          .expand(
            (module) => _dart(Directory('lib/features/$module/presentation')),
          )
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(
        content,
        isNot(matches(RegExp(r"features/[^']+/data/|\.\./\.\./[^/]+/data/"))),
      );
    });
  });
}

Iterable<File> _dart(Directory directory) sync* {
  if (!directory.existsSync()) return;
  yield* directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}
