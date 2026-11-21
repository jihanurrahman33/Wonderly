import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Solves the parent gate currently on screen.
Future<void> solveParentGate(WidgetTester tester) async {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.contains('×'));
  final m = RegExp(r'(\d) × (\d) =').firstMatch(text)!;
  final answer = int.parse(m.group(1)!) * int.parse(m.group(2)!);
  for (final digit in '$answer'.split('')) {
    await tester.tap(find.widgetWithText(InkWell, digit));
    await tester.pump();
  }
  await tester.tap(find.widgetWithIcon(InkWell, Icons.check_rounded));
  await tester.pumpAndSettle();
}
