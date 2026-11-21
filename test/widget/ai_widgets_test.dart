import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';

import '../helpers/fake_ai.dart';
import '../helpers/parent_gate.dart';
import '../helpers/pump_app.dart';

Future<void> goHome(WidgetTester tester) async {
  await tester.tap(find.text("Let's go"));
  await tester.pumpAndSettle();
}

String a2ui({
  String title = 'Wow Alex!',
  String body = 'You are doing great. Try some birds next.',
  String setId = 'birds',
}) =>
    '{"version":"v0.9","createSurface":{"surfaceId":"buddy","catalogId":"wonderly.buddy.v1"}}\n'
    '{"version":"v0.9","updateComponents":{"surfaceId":"buddy","components":['
    '{"id":"root","component":"BuddyCard","accent":"sky","title":"$title","body":"$body","child":"go"},'
    '{"id":"go","component":"ActionButton","label":"Play Birds",'
    '"action":{"event":{"name":"startQuiz","context":{"setId":"$setId"}}}}]}}';

Future<void> openSmartBuddyViaGate(WidgetTester tester) async {
  await tester.tap(find.text('Me'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Grown-ups zone'));
  await tester.pumpAndSettle();
  await solveParentGate(tester);
  await tester.scrollUntilVisible(
    find.text('Smart Buddy (on-device AI)'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Smart Buddy (on-device AI)'));
  await tester.pumpAndSettle();
}

void main() {
  group('A2UI buddy card', () {
    testWidgets('uses the built-in message when no model is installed', (
      tester,
    ) async {
      await pumpWonderly(tester, profile: savedProfile);
      await goHome(tester);
      await tester.pumpAndSettle();
      expect(find.text('Hi Alex!'), findsOneWidget);
      expect(
        find.textContaining('Ready for a quick round of Mammals'),
        findsOneWidget,
      );
      expect(find.text('Play Mammals'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the card button starts the suggested quiz', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await goHome(tester);
      await tester.tap(find.text('Play Mammals'));
      await tester.pumpAndSettle();
      expect(find.text('Which of these is a mammal?'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('draws the card the on-device model wrote', (tester) async {
      final llm = FakeLlm(reply: (_, _) => a2ui());
      await pumpWonderly(tester, profile: savedProfile, llm: llm);
      await goHome(tester);
      await tester.pumpAndSettle();
      expect(find.text('Wow Alex!'), findsOneWidget);
      expect(find.text('Hi Alex!'), findsNothing);
      expect(llm.users, hasLength(1));
      expect(llm.released, 1);

      await tester.tap(find.text('Play Birds'));
      await tester.pumpAndSettle();
      expect(find.text('Which bird cannot fly?'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('falls back when the model answers badly, unsafely or fails', (
      tester,
    ) async {
      for (final reply in [
        'I am a chatbot, here is a poem',
        a2ui(body: 'Visit http://bad.example now'),
        a2ui(setId: 'secret_set'),
        null,
      ]) {
        final llm = FakeLlm(reply: (_, _) => reply);
        await pumpWonderly(tester, profile: savedProfile, llm: llm);
        await goHome(tester);
        await tester.pumpAndSettle();
        expect(find.text('Hi Alex!'), findsOneWidget, reason: '$reply');
        await disposeApp(tester);
      }
    });
  });

  group('weekly note for grown-ups', () {
    Future<void> openGrownUps(WidgetTester tester) async {
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grown-ups zone'));
      await tester.pumpAndSettle();
      await solveParentGate(tester);
    }

    testWidgets('shows an A2UI report card with stat tiles', (tester) async {
      await pumpWonderly(
        tester,
        profile: savedProfile,
        extra: {'wonderly.progress.v1': '{"stars": 12}'},
      );
      await goHome(tester);
      await openGrownUps(tester);
      expect(find.text("Alex's week"), findsOneWidget);
      expect(find.text('Day streak'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
      await disposeApp(tester);
    });

    testWidgets('uses the model words for the weekly note when available', (
      tester,
    ) async {
      final llm = FakeLlm(
        reply: (_, _) =>
            a2ui(title: 'A great week!', body: 'Alex kept learning.'),
      );
      await pumpWonderly(tester, profile: savedProfile, llm: llm);
      await goHome(tester);
      await openGrownUps(tester);
      expect(find.text('A great week!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the note can be switched off', (tester) async {
      await pumpWonderly(
        tester,
        profile: savedProfile,
        extra: {'wonderly.settings.v1': '{"weeklyReport": false}'},
      );
      await goHome(tester);
      await openGrownUps(tester);
      expect(find.text("Alex's week"), findsNothing);
      await disposeApp(tester);
    });
  });

  group('Smart Buddy setup', () {
    testWidgets(
      'a sleeping buddy invites a grown-up; the gate leads to setup',
      (tester) async {
        final models = FakeModelManager();
        await pumpWonderly(tester, profile: savedProfile, models: models);
        await goHome(tester);
        await tester.pumpAndSettle();
        expect(find.textContaining('Smart Buddy is sleeping'), findsOneWidget);

        await tester.tap(find.textContaining('Smart Buddy is sleeping'));
        await tester.pumpAndSettle();
        expect(find.text('Grown-ups only'), findsOneWidget);
        await solveParentGate(tester);

        expect(find.text('Wake up Smart Buddy'), findsOneWidget);
        expect(find.text('Choose a model'), findsOneWidget);
        expect(find.text('Download 1.6 GB'), findsOneWidget);

        await tester.tap(find.text('Download 1.6 GB'));
        await tester.pumpAndSettle();
        expect(models.downloads, 1);
        expect(find.text('Downloading Qwen 2.5 1.5B'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(models.cancels, 1);
        await disposeApp(tester);
      },
    );

    testWidgets('mobile data needs an explicit confirmation', (tester) async {
      final models = FakeModelManager();
      await pumpWonderly(
        tester,
        profile: savedProfile,
        models: models,
        device: FakeDeviceStatus(wifi: false),
      );
      await goHome(tester);
      await openSmartBuddyViaGate(tester);

      await tester.tap(find.text('Download 1.6 GB'));
      await tester.pumpAndSettle();
      expect(find.text('Not on Wi-Fi'), findsOneWidget);
      expect(models.downloads, 0);

      await tester.tap(find.text('Wait for Wi-Fi'));
      await tester.pumpAndSettle();
      expect(models.downloads, 0);

      await tester.tap(find.text('Download 1.6 GB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download anyway'));
      await tester.pumpAndSettle();
      expect(models.downloads, 1);
      await disposeApp(tester);
    });

    testWidgets('the best-quality profile can be chosen', (tester) async {
      await pumpWonderly(tester, profile: savedProfile);
      await goHome(tester);
      await openSmartBuddyViaGate(tester);
      await tester.tap(find.textContaining('Best quality'));
      await tester.pumpAndSettle();
      expect(find.text('Download 2.6 GB'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'an installed model shows writing controls and can be removed',
      (tester) async {
        final models = FakeModelManager(const ModelInstalled());
        await pumpWonderly(tester, profile: savedProfile, models: models);
        await goHome(tester);
        await openSmartBuddyViaGate(tester);

        expect(find.text('Smart Buddy is awake'), findsOneWidget);
        expect(find.text('Write new quizzes'), findsOneWidget);
        expect(
          find.textContaining('questions written on this phone'),
          findsOneWidget,
        );

        await tester.tap(find.text('Remove model'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(models.deletes, 1);
        expect(find.text('Choose a model'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets('unsupported phones get a clear explanation, not a crash', (
      tester,
    ) async {
      final models = FakeModelManager(
        const ModelUnsupported('Smart Buddy needs Android 11 or newer.'),
      );
      await pumpWonderly(tester, profile: savedProfile, models: models);
      await goHome(tester);
      await openSmartBuddyViaGate(tester);
      expect(
        find.text('Smart Buddy needs Android 11 or newer.'),
        findsOneWidget,
      );
      expect(find.textContaining('Download'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('a failed download offers another try', (tester) async {
      final models = FakeModelManager(
        const ModelFailed(
          'No internet connection. Connect to Wi-Fi and try again.',
        ),
      );
      await pumpWonderly(tester, profile: savedProfile, models: models);
      await goHome(tester);
      await openSmartBuddyViaGate(tester);
      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(find.text('Download 1.6 GB'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('multiple learners', () {
    testWidgets('a second learner can be added and switched to', (
      tester,
    ) async {
      await pumpWonderly(tester, profile: savedProfile);
      await goHome(tester);
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Switch learner'));
      await tester.pumpAndSettle();
      expect(find.text('Who is playing?'), findsOneWidget);
      await tester.tap(find.text('Add a learner'));
      await tester.pumpAndSettle();

      expect(find.text('Who is learning?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Mia');
      await tester.tap(find.text('2nd'));
      await tester.pump();
      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();

      expect(find.text('Mia'), findsWidgets);
      expect(find.text('2nd Grade'), findsOneWidget);
      final roster = (await sl<ProfileRepository>().load()).valueOrNull!;
      expect(roster.learners.map((l) => l.name), ['Alex', 'Mia']);

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch learner'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();
      expect(sl<ProfileRepository>(), isNotNull);
      final after = (await sl<ProfileRepository>().load()).valueOrNull!;
      expect(after.active?.name, 'Alex');
      await disposeApp(tester);
    });
  });
}
