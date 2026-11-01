import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scope = <String>['market', 'trade_ideas', 'journal'];

void main() {
  group('phase 2 strict clean architecture', () {
    for (final feature in _scope) {
      test('$feature has complete clean architecture layers', () {
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

      test('$feature domain is platform-independent pure Dart', () {
        _expectNoImports(Directory('lib/features/$feature/domain'), const [
          'package:flutter/',
          '/data/',
          '/presentation/',
          'tradex_api_client.dart',
          'shared_preferences',
          'flutter_timezone',
          'dart:io',
        ]);
      });

      test('$feature presentation depends inward', () {
        final presentation = Directory('lib/features/$feature/presentation');
        _expectNoImports(presentation, const [
          '/data/',
          'tradex_api_client.dart',
          'api_exception.dart',
          'shared_preferences',
          'dart:convert',
          'dart:io',
        ]);
        _expectNoSource(presentation, const [
          'Map<String, dynamic>',
          'Map<String,dynamic>',
        ]);
      });

      test('$feature data never imports presentation', () {
        _expectNoImports(Directory('lib/features/$feature/data'), const [
          '/presentation/',
        ]);
      });

      test('$feature repository contracts are enforced', () {
        final contracts = _dartFiles(
          Directory('lib/features/$feature/domain/repositories'),
        ).map((file) => file.readAsStringSync()).join('\n');
        final implementations = _dartFiles(
          Directory('lib/features/$feature/data/repositories'),
        ).map((file) => file.readAsStringSync()).join('\n');
        expect(contracts, contains('abstract interface class'));
        expect(implementations, contains('implements'));
      });

      test('$feature source files satisfy the size guard', () {
        final oversized = _dartFiles(Directory('lib/features/$feature'))
            .where((file) => file.lengthSync() > 34 * 1024)
            .map((file) => file.path)
            .toList();
        expect(
          oversized,
          isEmpty,
          reason: 'Files over the 34 KiB guard: $oversized',
        );
      });
    }

    test('cross-feature access uses domain or a public facade', () {
      final violations = <String>[];
      for (final feature in _scope) {
        for (final file in _dartFiles(Directory('lib/features/$feature'))) {
          for (final line in file.readAsLinesSync()) {
            if (!line.trimLeft().startsWith('import ')) continue;
            final normalized = line.replaceAll('\\', '/');
            final target = _scope
                .where((candidate) => candidate != feature)
                .where((candidate) => normalized.contains('/$candidate/'));
            if (target.isEmpty) continue;
            final allowed =
                normalized.contains('/domain/') ||
                normalized.endsWith("/$feature.dart';") ||
                normalized.contains('/market/market.dart');
            if (!allowed) violations.add('${file.path}: $line');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}

Iterable<File> _dartFiles(Directory directory) => directory
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void _expectNoImports(Directory directory, List<String> forbidden) {
  final violations = <String>[];
  for (final file in _dartFiles(directory)) {
    for (final line in file.readAsLinesSync()) {
      if (!line.trimLeft().startsWith('import ')) continue;
      for (final token in forbidden) {
        if (line.toLowerCase().contains(token)) {
          violations.add('${file.path}: $line');
        }
      }
    }
  }
  expect(violations, isEmpty, reason: violations.join('\n'));
}

void _expectNoSource(Directory directory, List<String> forbidden) {
  final violations = <String>[];
  for (final file in _dartFiles(directory)) {
    final source = file.readAsStringSync();
    for (final token in forbidden) {
      if (source.contains(token)) violations.add('${file.path}: $token');
    }
  }
  expect(violations, isEmpty, reason: violations.join('\n'));
}
