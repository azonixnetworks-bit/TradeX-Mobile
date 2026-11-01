import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('support presentation stays split into maintainable units', () {
    final presentationFiles = _dartFiles(
      Directory('lib/features/support/presentation'),
    );

    for (final file in presentationFiles) {
      final lineCount = file.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(1000),
        reason: '${file.path} has $lineCount lines and should be split',
      );
    }
  });

  for (final feature in const ['support', 'copy_trading', 'funded_advisor']) {
    final featureRoot = Directory('lib/features/$feature');

    test('$feature domain is framework and infrastructure independent', () {
      final domainFiles = _dartFiles(Directory('${featureRoot.path}/domain'));
      expect(domainFiles, isNotEmpty);

      for (final file in domainFiles) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains('package:flutter/')),
          reason: '${file.path} must not depend on Flutter',
        );
        expect(
          source,
          isNot(contains('/data/')),
          reason: '${file.path} must not depend on the data layer',
        );
        expect(
          source,
          isNot(contains('/presentation/')),
          reason: '${file.path} must not depend on presentation',
        );
        expect(
          source,
          isNot(contains('TradeXApiClient')),
          reason: '${file.path} must not know the API client',
        );
      }
    });

    test('$feature presentation does not import data or network clients', () {
      final presentationFiles = _dartFiles(
        Directory('${featureRoot.path}/presentation'),
      );
      expect(presentationFiles, isNotEmpty);

      for (final file in presentationFiles) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains('../data/')),
          reason: '${file.path} must use domain contracts',
        );
        expect(
          source,
          isNot(contains('TradeXApiClient')),
          reason: '${file.path} must receive domain use cases',
        );
      }
    });
  }
}

List<File> _dartFiles(Directory directory) => directory
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);
