// Renders the app icon from the bundled owl artwork.
// Run: flutter test tool/render_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  WidgetTester tester, {
  required String path,
  required Color? background,
  required double owlSize,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: 1024,
            height: 1024,
            color: background,
            alignment: Alignment.center,
            child: SvgPicture.asset('assets/svg/owl.svg', width: owlSize, height: owlSize),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render icons', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _render(tester, path: 'assets/icon/icon.png', background: const Color(0xFFF7BE4B), owlSize: 700);
    await _render(tester, path: 'assets/icon/icon_fg.png', background: null, owlSize: 560);
  });
}
