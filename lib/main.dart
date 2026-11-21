import 'package:wonderly/app.dart';
import 'package:wonderly/bootstrap.dart';
import 'package:wonderly/core/di/injection.dart';

Future<void> main() async {
  await bootstrap(() async {
    await configureDependencies();
    return const WonderlyApp();
  });
}
