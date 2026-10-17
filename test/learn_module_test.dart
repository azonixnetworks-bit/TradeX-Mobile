import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/learn/presentation/learn_module.dart';

void main() {
  testWidgets('text lesson renderer presents protected lesson notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TextLessonRenderer(text: 'Market structure')),
      ),
    );

    expect(find.text('Lesson Notes'), findsOneWidget);
    expect(find.text('Market structure'), findsOneWidget);
  });

  testWidgets('PDF renderer clearly keeps content view-only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PdfLessonRenderer())),
    );

    expect(find.text('Protected PDF'), findsOneWidget);
    expect(
      find.textContaining('Download and sharing are disabled'),
      findsOneWidget,
    );
  });
}
