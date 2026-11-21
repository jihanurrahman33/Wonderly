import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';

import '../helpers/play_quiz.dart';
import '../helpers/pump_app.dart';

Future<void> goHome(WidgetTester tester) async {
  await tester.tap(find.text("Let's go"));
  await tester.pumpAndSettle();
}

void main() {
  Future<void> playWholeSet(
    WidgetTester tester,
    String setId,
    String cardText,
  ) async {
    final catalog = await currentCatalog(tester);
    final set = catalog.setById(setId)!;
    await tester.scrollUntilVisible(
      find.text(cardText),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(cardText));
    await tester.pumpAndSettle();
    expect(find.text('1/${set.length}'), findsOneWidget);

    for (var i = 0; i < set.length; i++) {
      await answerCorrectly(
        tester,
        set.questions[i],
        last: i == set.length - 1,
      );
    }
    expect(find.text('Great job, Alex!'), findsOneWidget);
    expect(find.text('${set.length}/${set.length}'), findsOneWidget);
  }

  testWidgets('logic puzzles: every pattern can be solved through the UI', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpWonderly(tester, profile: savedProfile);
    await goHome(tester);
    await playWholeSet(tester, 'logic_puzzles', 'Logic puzzles');
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('geometry: shapes are matched by tapping a piece then its spot', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpWonderly(tester, profile: savedProfile);
    await goHome(tester);
    await playWholeSet(tester, 'geometry_shapes', 'Geometry shapes');
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('numbers: arithmetic is generated for the learner grade', (
    tester,
  ) async {
    await pumpWonderly(tester, profile: savedProfile);
    await goHome(tester);
    await playWholeSet(tester, 'number_fun', 'Number fun');
    await disposeApp(tester);
  });

  testWidgets('a wrong shape on a spot is turned away with a hint', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpWonderly(tester, profile: savedProfile);
    await goHome(tester);
    final catalog = await currentCatalog(tester);
    final set = catalog.setById('geometry_shapes')!;
    // Play up to the first drag question.
    await tester.scrollUntilVisible(
      find.text('Geometry shapes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Geometry shapes'));
    await tester.pumpAndSettle();
    var index = 0;
    while (set.questions[index] is! ShapeMatchQuestion) {
      await answerCorrectly(tester, set.questions[index], last: false);
      index++;
    }
    final q = set.questions[index] as ShapeMatchQuestion;
    final piece = q.shapes.first;
    final wrongSpot = q.shapes.last;
    await tester.tap(
      find.bySemanticsLabel(
        RegExp('^${piece[0].toUpperCase()}${piece.substring(1)} piece'),
      ),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Empty $wrongSpot spot'));
    await tester.pump();
    expect(find.text('Try another spot for the $piece.'), findsOneWidget);
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('a used up daily limit shows the break screen', (tester) async {
    final today = DayKey.of(DateTime.now());
    await pumpWonderly(
      tester,
      profile: savedProfile,
      extra: {
        'wonderly.settings.v1': '{"dailyLimitMinutes": 10}',
        'wonderly.progress.v1': '{"dailySeconds": {"$today": 600}}',
      },
    );
    await goHome(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Time for a break!'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('Keep exploring'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('rewards open an earned badge and explain a locked one', (
    tester,
  ) async {
    await pumpWonderly(
      tester,
      profile: savedProfile,
      extra: {
        'wonderly.progress.v1':
            '{"stars": 26, "badges": ["zoologyExplorer"], "bestStreak": 6}',
      },
    );
    await goHome(tester);
    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();

    expect(find.text('Badges · 1 of 6'), findsOneWidget);
    expect(find.text('4 more stars to unlock Plant Pal'), findsOneWidget);
    expect(find.text('Best: 6 days'), findsOneWidget);

    await tester.tap(find.text('Plant Pal'));
    await tester.pump();
    expect(find.text('Plant Pal: Collect 30 stars'), findsOneWidget);

    await tester.tap(find.text('Zoology Explorer'));
    await tester.pumpAndSettle();
    expect(find.text('New badge!'), findsOneWidget);
    expect(find.text('+5 bonus stars'), findsOneWidget);

    await tester.tap(find.text('Collect'));
    await tester.pumpAndSettle();
    expect(find.text('My rewards'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('progress page summarises the week and each subject', (
    tester,
  ) async {
    await pumpWonderly(
      tester,
      profile: savedProfile,
      extra: {
        'wonderly.progress.v1':
            '{"stars": 5, "correctQuestionIds": ["a","b","c"], '
            '"completedSetIds": ["logic_puzzles"]}',
      },
    );
    await goHome(tester);
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My progress'));
    await tester.pumpAndSettle();

    expect(find.text('Stars this week'), findsOneWidget);
    expect(find.text('5 total'), findsOneWidget);
    expect(find.text('Questions right'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('100%'), findsOneWidget); // Logic is fully done.
    await disposeApp(tester);
  });

  testWidgets(
    'a corrupt save falls back to a fresh start instead of crashing',
    (tester) async {
      await pumpWonderly(
        tester,
        profile: savedProfile,
        extra: {
          'wonderly.progress.v1': '{{{ not json',
          'wonderly.settings.v1': '[]',
        },
      );
      await goHome(tester);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('0-day streak'), findsOneWidget);
      await disposeApp(tester);
    },
  );
}
