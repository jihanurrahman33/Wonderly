import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/app_logger.dart';

/// Logs bloc errors instead of letting them disappear.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Unhandled error in ${bloc.runtimeType}.',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

/// Runs [builder] inside the app's global error handling.
///
/// Every uncaught error is logged; widgets that fail to build show a friendly
/// message instead of the red error screen in release builds.
Future<void> bootstrap(Future<Widget> Function() builder) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      FlutterError.onError = (details) {
        AppLogger.error(
          'Flutter framework error.',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error('Platform error.', error: error, stackTrace: stack);
        return true;
      };
      if (kReleaseMode) {
        ErrorWidget.builder = (_) => const _FriendlyErrorWidget();
      }

      Bloc.observer = AppBlocObserver();
      runApp(await builder());
    },
    (error, stack) => AppLogger.error(
      'Uncaught zone error.',
      error: error,
      stackTrace: stack,
    ),
  );
}

class _FriendlyErrorWidget extends StatelessWidget {
  const _FriendlyErrorWidget();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Oops! Something went wrong.\nPlease go back and try again.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: AppText.heading(20),
          ),
        ),
      ),
    );
  }
}
