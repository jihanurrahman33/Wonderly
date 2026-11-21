import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/utils/clock.dart';

import '../helpers/pump_app.dart';

Future<void> goHome(WidgetTester tester) async {
  await tester.tap(find.text("Let's go"));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('logic puzzle: pick the next shape in the pattern', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpWonderly(tester, profile: savedProfile);
    await goHome(tester);

    await tester.scrollUntilVisible(
      find.text('Logic puzzles'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Logic puzzles'));
    await tester.pumpAndSettle();
    expect(find.text('What comes next?'), findsOneWidget);
    expect(find.text('1/9'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Circle'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('That is right'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2/9'), findsOneWidget);
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('geometry: match every shape by tapping piece then spot', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpWonderly(tester, profile: savedProfile);
    await goHome(tester);

    await tester.scrollUntilVisible(
      find.text('Geometry shapes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Geometry shapes'));
    await tester.pumpAndSettle();
    expect(find.text('Drag each shape to its match'), findsOneWidget);

    // Next is locked until every shape is placed.
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('1/6'), findsOneWidget);

    // A piece dropped on the wrong spot is turned away with a hint.
    await tester.tap(find.bySemanticsLabel(RegExp('^Circle piece')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Empty triangle spot'));
    await tester.pump();
    expect(find.text('Try another spot for the circle.'), findsOneWidget);

    for (final shape in ['circle', 'triangle', 'square']) {
      final name = '${shape[0].toUpperCase()}${shape.substring(1)}';
      if (shape != 'circle') {
        await tester.tap(find.bySemanticsLabel(RegExp('^$name piece')));
        await tester.pump();
      }
      await tester.tap(find.bySemanticsLabel('Empty $shape spot'));
      await tester.pump();
    }
    expect(find.text('All done!'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2/6'), findsOneWidget);
    expect(find.text('How many sides does a triangle have?'), findsOneWidget);
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
