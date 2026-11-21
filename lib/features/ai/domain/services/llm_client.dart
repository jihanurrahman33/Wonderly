import 'package:wonderly/core/error/result.dart';

/// Runs prompts on the device's language model.
abstract interface class LlmClient {
  /// Whether a model is installed and can answer right now.
  bool get isReady;

  /// Sends one prompt and returns the full reply.
  ///
  /// When [jsonSchema] is given the reply is constrained to that schema if the
  /// engine supports it; callers must still validate the result.
  Future<Result<String>> complete({
    required String system,
    required String user,
    Map<String, Object?>? jsonSchema,
    int maxOutputTokens = 400,
    double temperature = 0.7,
  });

  /// Frees the model's memory. Safe to call at any time.
  Future<void> release();
}
