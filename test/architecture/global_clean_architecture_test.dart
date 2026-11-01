import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final featureRoot = Directory('lib/features');
  final features =
      featureRoot
          .listSync()
          .whereType<Directory>()
          .where((directory) => _dart(directory).isNotEmpty)
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  group('global clean architecture scanner', () {
    test('discovers every feature automatically', () {
      expect(features.length, greaterThanOrEqualTo(15));
    });

    for (final feature in features) {
      final name = _name(feature);

      test('$name domain is pure Dart', () {
        _expectNoImports(Directory('${feature.path}/domain'), const [
          'package:flutter/',
          '/data/',
          '/presentation/',
          'core/network/',
          'core/storage/',
          'shared_preferences',
          'flutter_secure_storage',
          'image_picker',
          'url_launcher',
          'flutter_timezone',
          'local_auth',
          'dart:io',
        ]);
      });

      test('$name presentation depends on abstractions only', () {
        final directory = Directory('${feature.path}/presentation');
        _expectNoImports(directory, const [
          '/data/',
          'core/network/',
          'core/storage/',
          'core/preferences/',
          'shared_preferences',
          'flutter_secure_storage',
          'image_picker',
          'url_launcher',
          'flutter_timezone',
          'local_auth',
          'dart:io',
          'dart:convert',
        ]);
        for (final file in _dart(directory)) {
          final source = file.readAsStringSync();
          expect(
            source,
            isNot(
              matches(
                RegExp(
                  r'\b[A-Z][A-Za-z0-9_]*(RepositoryImpl|Dependencies|ApiClient|DataSource|Store)\s*\(',
                ),
              ),
            ),
            reason: '${file.path} constructs infrastructure',
          );
        }
      });

      test('$name data never imports presentation', () {
        _expectNoImports(Directory('${feature.path}/data'), const [
          '/presentation/',
        ]);
      });

      test('$name has no cross-feature data dependency', () {
        for (final file in _dart(feature)) {
          final relative = file.path.replaceAll('\\', '/');
          final layer = relative.contains('/data/') ? 'data' : 'non-data';
          final source = file.readAsStringSync();
          final imports = RegExp(r'''import\s+['"]([^'"]+)['"]''')
              .allMatches(source);
          for (final match in imports) {
            final value = match.group(1)!;
            final crossData = RegExp(
              r'features/([^/]+)/data/|\.\./\.\./([^/]+)/data/',
            ).firstMatch(value);
            if (crossData == null) continue;
            final target = crossData.group(1) ?? crossData.group(2);
            expect(
              target == name && layer == 'data',
              isTrue,
              reason: '${file.path} imports another feature data layer: $value',
            );
          }
        }
      });
    }

    test('Dart files stay below the mixed-responsibility size guard', () {
      const maximumBytes = 40 * 1024;
      final oversized = <String>[];
      for (final file in _dart(Directory('lib'))) {
        if (file.lengthSync() > maximumBytes) {
          oversized.add('${file.path} (${file.lengthSync()} bytes)');
        }
      }
      expect(oversized, isEmpty, reason: oversized.join('\n'));
    });

    test('repository implementations declare a contract', () {
      final offenders = <String>[];
      for (final feature in features) {
        for (final file in _dart(Directory('${feature.path}/data'))) {
          final source = file.readAsStringSync();
          final implementations = RegExp(
            r'class\s+\w+(RepositoryImpl|Repository)\s+',
          ).allMatches(source);
          if (implementations.isNotEmpty &&
              !source.contains(' implements ') &&
              !source.contains(' extends ')) {
            offenders.add(file.path);
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}

void _expectNoImports(Directory directory, List<String> forbidden) {
  for (final file in _dart(directory)) {
    final source = file.readAsStringSync();
    final imports = RegExp(r'''import\s+['"]([^'"]+)['"]''')
        .allMatches(source)
        .map((match) => match.group(1)!)
        .join('\n');
    for (final value in forbidden) {
      expect(
        imports,
        isNot(contains(value)),
        reason: '${file.path} imports $value',
      );
    }
  }
}

List<File> _dart(Directory directory) => directory.existsSync()
    ? directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
    : const [];

String _name(Directory directory) =>
    directory.path.replaceAll('\\', '/').split('/').last;
