import 'dart:async';

import 'package:wonderly/app.dart';
import 'package:wonderly/bootstrap.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/services/natural_voice.dart';
import 'package:wonderly/features/ai/data/edge_ai_model_manager.dart';

Future<void> main() async {
  await bootstrap(() async {
    await configureDependencies();
    // Never blocks the app: without the engine the built-in questions are used.
    await EdgeAiRuntime.start();
    // Finds out whether the natural voice is already installed.
    unawaited(sl<NaturalVoice>().refresh());
    return const WonderlyApp();
  });
}
