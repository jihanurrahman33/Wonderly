import 'package:wonderly/app.dart';
import 'package:wonderly/bootstrap.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/features/ai/data/edge_ai_model_manager.dart';

Future<void> main() async {
  await bootstrap(() async {
    await configureDependencies();
    // Never blocks the app: without the engine the built-in questions are used.
    await EdgeAiRuntime.start();
    return const WonderlyApp();
  });
}
