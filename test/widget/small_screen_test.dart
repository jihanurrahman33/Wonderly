import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Guards against overflow on small phones with the largest text setting.
void main() {
  testWidgets('main tabs and the quiz fit a 320x568 phone with large text', (
    tester,
  ) async {
    await pumpWonderly(
      tester,
      profile: savedProfile,
      extra: const {'wonderly.settings.v1': '{"textSize":"large"}'},
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();

    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle();

    for (final tab in ['Learn', 'Rewards', 'Me', 'Home']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Which of these is a mammal?'), findsOneWidget);
    await tester.tap(find.text('Dolphin'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });
}
