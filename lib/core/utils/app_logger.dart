import 'dart:developer' as developer;

/// Thin logging facade so the sink can later be swapped (for example for a
/// privacy-safe crash reporter) without touching call sites.
///
/// Never log personal data such as a child's name.
abstract final class AppLogger {
  static void info(String message) =>
      developer.log(message, name: 'wonderly', level: 800);

  static void warning(String message, [Object? error]) =>
      developer.log(message, name: 'wonderly', level: 900, error: error);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      developer.log(
        message,
        name: 'wonderly',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
