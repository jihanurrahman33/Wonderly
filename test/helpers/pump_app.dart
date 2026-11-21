import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonderly/app.dart';
import 'package:wonderly/core/di/injection.dart';

bool _fontsLoaded = false;

/// Loads the bundled fonts so tests measure text with real glyph widths
/// (the default test font makes every character a wide square).
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  for (final family in ['Fredoka', 'Nunito']) {
    final bytes = File('assets/fonts/$family.ttf').readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
  _fontsLoaded = true;
}

/// A saved profile, as the app stores it.
const savedProfile = {'name': 'Alex', 'grade': 3, 'buddy': 'cat'};

/// Boots the real app with in-memory storage.
///
/// [profile] pre-fills a learner so the test can skip onboarding;
/// [extra] adds raw preference entries (for example saved progress).
Future<void> pumpWonderly(
  WidgetTester tester, {
  Map<String, Object?>? profile,
  Map<String, Object> extra = const {},
}) async {
  await loadAppFonts();
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    if (profile != null) 'wonderly.profile.v1': jsonEncode(profile),
    ...extra,
  });
  await sl.reset();
  await configureDependencies(
    preferences: await SharedPreferences.getInstance(),
    // Read from disk so the test clock never waits on platform asset I/O.
    loadCatalogJson: () async =>
        File('assets/data/questions.json').readAsStringSync(),
  );
  await tester.pumpWidget(const WonderlyApp());
  await tester.pumpAndSettle();
}

/// Replaces the tree so pages dispose their timers and streams.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
