import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _features = <String>[
  'investments',
  'notifications',
  'risk_reward',
  'affiliate',
  'learn',
];

void main() {
  group('phase 1 clean architecture boundaries', () {
    for (final feature in _features) {
      test('$feature has the required layers', () {
        final root = Directory('lib/features/$feature');
        for (final path in const <String>[
          'domain/entities',
          'domain/repositories',
          'domain/usecases',
          'data/datasources',
          'data/models',
          'data/mappers',
          'data/repositories',
          'presentation/bloc',
          'presentation/screens',
          'presentation/widgets',
        ]) {
          expect(
            Directory('${root.path}/$path').existsSync(),
            isTrue,
            reason: '$feature is missing $path',
          );
        }
        expect(
          File('${root.path}/${feature}_dependencies.dart').existsSync(),
          isTrue,
        );
      });

      test('$feature domain is pure Dart', () {
        _expectNoImports(
          Directory('lib/features/$feature/domain'),
          const <String>[
            'package:flutter/',
            '/data/',
            '/presentation/',
            'tradex_api_client.dart',
            'shared_preferences',
            'app_preferences.dart',
            'dart:io',
          ],
        );
      });

      test('$feature presentation depends inward only', () {
        _expectNoImports(
          Directory('lib/features/$feature/presentation'),
          const <String>[
            '/data/',
            'tradex_api_client.dart',
            'shared_preferences',
            'app_preferences.dart',
          ],
        );
      });

      test('$feature data never imports presentation', () {
        _expectNoImports(
          Directory('lib/features/$feature/data'),
          const <String>['/presentation/'],
        );
      });

      test('$feature repository contracts live in domain', () {
        final contracts = Directory('lib/features/$feature/domain/repositories')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));
        expect(contracts, isNotEmpty);
        expect(
          contracts.any(
            (file) =>
                file.readAsStringSync().contains('abstract interface class'),
          ),
          isTrue,
        );
      });

      test('$feature source files stay reviewable', () {
        final oversized = Directory('lib/features/$feature')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => file.lengthSync() > 36 * 1024)
            .map((file) => file.path)
            .toList();
        expect(oversized, isEmpty, reason: 'Files over 36 KiB: $oversized');
      });
    }
  });
}

void _expectNoImports(Directory directory, List<String> forbidden) {
  final violations = <String>[];
  for (final file
      in directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))) {
    final imports = file.readAsLinesSync().where(
      (line) => line.trimLeft().startsWith('import '),
    );
    for (final import in imports) {
      for (final token in forbidden) {
        if (import.toLowerCase().contains(token)) {
          violations.add('${file.path}: $import');
        }
      }
    }
  }
  expect(violations, isEmpty, reason: violations.join('\n'));
}
