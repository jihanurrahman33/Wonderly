import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';

import '../helpers/pump_app.dart';

void main() {
  group('first run', () {
    testWidgets('splash, welcome tour and profile setup lead to Home', (
      tester,
    ) async {
      await pumpWonderly(tester);

      expect(find.text('Wonderly'), findsOneWidget);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();

      expect(find.text('Learn by playing'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Collect stars and badges'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Grown-ups stay in the loop'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(find.text('Who is learning?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Sam');
      await tester.tap(find.text('4th'));
      await tester.pump();
      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();

      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('4th Grade'), findsOneWidget);
      final saved = (await sl<ProfileRepository>().load()).valueOrNull;
      expect(saved?.name, 'Sam');
      expect(saved?.grade, 4);
      await disposeApp(tester);
    });

    testWidgets('Skip jumps straight to profile setup', (tester) async {
      await pumpWonderly(tester);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Who is learning?'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('an empty name shows a friendly error and stays put', (
      tester,
    ) async {
      await pumpWonderly(tester);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();

      expect(find.text('Please type your name.'), findsOneWidget);
      expect(find.text('Who is learning?'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('protected pages redirect to splash without a profile', (
      tester,
    ) async {
      await pumpWonderly(tester);
      // The router starts at splash; nothing else is reachable yet.
      expect(find.text('Home'), findsNothing);
      expect(find.text("Let's go"), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('returning learner', () {
    testWidgets('splash goes straight to Home', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('3rd Grade'), findsOneWidget);
      expect(find.text('Keep exploring'), findsOneWidget);
      expect(find.text('Geometry shapes'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('bottom navigation switches between tabs', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Learn'));
      await tester.pumpAndSettle();
      expect(find.text('What shall we learn?'), findsOneWidget);

      await tester.tap(find.text('Rewards'));
      await tester.pumpAndSettle();
      expect(find.text('My rewards'), findsOneWidget);
      expect(find.text('Badges · 0 of 6'), findsOneWidget);

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      expect(find.text('Grown-ups zone'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Numbers is marked as coming soon', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Numbers'));
      await tester.pump();
      expect(find.text('Coming soon!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Zoology lists its quiz sets with the locked one dimmed', (
      tester,
    ) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zoology'));
      await tester.pumpAndSettle();

      expect(find.text('Mammals'), findsOneWidget);
      expect(find.text('Zoology Quiz'), findsOneWidget);
      expect(find.text('Earn 30 stars to open'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('quiz', () {
    testWidgets('answer, see feedback and move to the next question', (
      tester,
    ) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Which of these is a mammal?'), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);

      await tester.tap(find.text('Dolphin'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('That is right'), findsOneWidget);
      expect(find.text('+1 star'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2/6'), findsOneWidget);
      expect(
        find.text('Which animal has babies that are born alive?'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('a wrong answer gets gentle feedback and no star', (
      tester,
    ) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shark'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Good try! Almost there'), findsOneWidget);
      expect(find.text('+1 star'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Hint shows the question hint', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hint'));
      await tester.pump();
      expect(
        find.text('It breathes air and feeds milk to its babies.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('a finished quiz shows results and a review sheet', (
      tester,
    ) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      // Mammals: answer 0..5 picks (indexes of correct options listed here).
      const answers = ['Dolphin', 'Cow', 'Milk', 'Bat', 'Blue whale', 'Whale'];
      for (final label in answers) {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label == 'Whale' ? 'Finish' : 'Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Great job, Alex!'), findsOneWidget);
      expect(find.text('You finished Mammals'), findsOneWidget);
      expect(find.text('6/6'), findsOneWidget);

      await tester.tap(find.text('Review answers'));
      await tester.pumpAndSettle();
      expect(find.text('Your answers'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('grown-ups zone', () {
    Future<void> openGate(WidgetTester tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grown-ups zone'));
      await tester.pumpAndSettle();
    }

    Future<void> typeNumber(WidgetTester tester, int value) async {
      for (final digit in '$value'.split('')) {
        await tester.tap(find.widgetWithText(InkWell, digit));
        await tester.pump();
      }
    }

    int shownAnswer(WidgetTester tester) {
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((s) => s.contains('×'));
      final m = RegExp(r'(\d) × (\d) =').firstMatch(text)!;
      return int.parse(m.group(1)!) * int.parse(m.group(2)!);
    }

    testWidgets('the gate blocks a wrong answer and shows a new question', (
      tester,
    ) async {
      await openGate(tester);
      expect(find.text('Grown-ups only'), findsOneWidget);

      await typeNumber(tester, shownAnswer(tester) + 1);
      await tester.tap(find.widgetWithIcon(InkWell, Icons.check_rounded));
      await tester.pump();

      expect(find.text('Not quite. Here is a new question.'), findsOneWidget);
      expect(find.text('Daily play limit'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the right answer opens the dashboard with the limit', (
      tester,
    ) async {
      await openGate(tester);
      await typeNumber(tester, shownAnswer(tester));
      await tester.tap(find.widgetWithIcon(InkWell, Icons.check_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Daily play limit'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('settings', () {
    testWidgets('toggles and text size persist', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Sound effects'), findsOneWidget);
      await tester.tap(find.text('Sound effects'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Text size L'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy for families'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No analytics'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
