import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/features/learning/data/live_catalog_repository.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';

/// The catalog the running app is using (same clock, same day-seeded content).
Future<Catalog> currentCatalog(WidgetTester tester) async {
  final result = await tester.runAsync(
    () => sl<LiveCatalogRepository>().load(),
  );
  return result!.valueOrNull!;
}

String _title(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

/// Answers [question] correctly through the real UI and moves on.
///
/// Needs semantics enabled for pattern and shape questions.
Future<void> answerCorrectly(
  WidgetTester tester,
  Question question, {
  required bool last,
}) async {
  switch (question) {
    case ChoiceQuestion():
      await tester.tap(find.text(question.options[question.answerIndex].label));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(last ? 'Finish' : 'Next'));
    case PatternQuestion():
      await tester.tap(
        find.bySemanticsLabel(_title(question.options[question.answerIndex])),
      );
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(last ? 'Finish' : 'Next'));
    case ShapeMatchQuestion():
      for (final shape in question.shapes) {
        await tester.tap(
          find.bySemanticsLabel(RegExp('^${_title(shape)} piece')),
        );
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Empty $shape spot'));
        await tester.pump();
      }
      await tester.tap(find.text(last ? 'Finish' : 'Next'));
  }
  await tester.pumpAndSettle();
}
