import 'dart:async';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/domain/services/model_manager.dart';

/// [LlmClient] that runs prompts on the installed on-device model.
///
/// Calls are serialised (one model, one conversation at a time) and every
/// failure becomes a [Failure]; nothing is thrown to callers.
class EdgeAiLlmClient implements LlmClient {
  EdgeAiLlmClient(this._manager);

  static const _contextTokens = 2048;

  final ModelManager _manager;
  InferenceModel? _model;
  Future<void> _queue = Future<void>.value();

  @override
  bool get isReady => _manager.current is ModelInstalled;

  @override
  Future<Result<String>> complete({
    required String system,
    required String user,
    Map<String, Object?>? jsonSchema,
    int maxOutputTokens = 400,
    double temperature = 0.7,
  }) {
    final completer = Completer<Result<String>>();
    _queue = _queue.then((_) async {
      completer.complete(
        await _run(system, user, jsonSchema, maxOutputTokens, temperature),
      );
    });
    return completer.future;
  }

  Future<Result<String>> _run(
    String system,
    String user,
    Map<String, Object?>? jsonSchema,
    int maxOutputTokens,
    double temperature,
  ) async {
    if (!isReady) {
      return const Result.failure(
        PlatformFailure('The on-device model is not installed.'),
      );
    }
    InferenceChat? chat;
    try {
      final model = _model ??= await FlutterEdgeAi.getActiveModel(
        maxTokens: _contextTokens,
        preferredBackend: PreferredBackend.cpu,
      );
      ResponseFormat? format;
      if (jsonSchema != null) {
        final candidate = ResponseFormat.jsonSchema(jsonSchema);
        // Only constrain the output when the engine can enforce it.
        if (model.refusalFor(candidate) == null) format = candidate;
      }
      chat = await model.openChat(
        systemInstruction: system,
        temperature: temperature,
        topK: 40,
        maxOutputTokens: maxOutputTokens,
        responseFormat: format,
      );
      await chat.addQueryChunk(Message.text(text: user, isUser: true));
      final reply = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) reply.write(response.token);
      }
      return Result.success(reply.toString());
    } on NoActiveModelError {
      return const Result.failure(
        PlatformFailure('No on-device model is active.'),
      );
    } on StructuredOutputException catch (e) {
      return Result.failure(
        DataFailure('The model did not follow the format: $e'),
      );
    } on Object catch (e, s) {
      AppLogger.error('On-device generation failed.', error: e, stackTrace: s);
      // A failed model may be in a bad state; reload it next time.
      await release();
      return const Result.failure(
        PlatformFailure('The on-device model could not answer.'),
      );
    } finally {
      try {
        await chat?.close();
      } on Object catch (e) {
        AppLogger.warning('Could not close the chat.', e);
      }
    }
  }

  @override
  Future<void> release() async {
    final model = _model;
    _model = null;
    try {
      await model?.close();
    } on Object catch (e) {
      AppLogger.warning('Could not release the model.', e);
    }
  }
}
