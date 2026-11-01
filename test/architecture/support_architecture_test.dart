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

  test('affiliate presentation stays split into maintainable units', () {
    final presentationFiles = _dartFiles(
      Directory('lib/features/affiliate/presentation'),
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

  test('risk reward presentation stays split into maintainable units', () {
    final presentationFiles = _dartFiles(
      Directory('lib/features/risk_reward/presentation'),
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

  test('learn presentation stays split into maintainable units', () {
    final presentationFiles = _dartFiles(
      Directory('lib/features/learn/presentation'),
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

  test('secure workflows stay split into maintainable units', () {
    final workflowFiles = _dartFiles(
      Directory('lib/features/catalog/presentation/secure_workflows'),
    );

    for (final file in workflowFiles) {
      final lineCount = file.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(1000),
        reason: '${file.path} has $lineCount lines and should be split',
      );
    }
  });

  test('home dashboard stays split into maintainable units', () {
    final dashboardFiles = _dartFiles(
      Directory('lib/features/home/presentation/home_dashboard'),
    );

    for (final file in dashboardFiles) {
      final lineCount = file.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(1000),
        reason: '${file.path} has $lineCount lines and should be split',
      );
    }
  });

  test('trade journal presentation stays split into maintainable units', () {
    final presentationFiles = _dartFiles(
      Directory('lib/features/journal/presentation'),
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

  test('crypto market stays split into maintainable units', () {
    final marketFiles = _dartFiles(
      Directory('lib/features/market/presentation/crypto_market'),
    );

    for (final file in marketFiles) {
      final lineCount = file.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(1000),
        reason: '${file.path} has $lineCount lines and should be split',
      );
    }
  });

  test('copy trading presentation stays split into maintainable units', () {
    final presentationFiles = _dartFiles(
      Directory('lib/features/copy_trading/presentation'),
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
