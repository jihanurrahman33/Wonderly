import 'dart:async';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/data/device_capability.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/domain/services/model_manager.dart';

/// Starts the on-device engine once. Never throws: when the engine cannot
/// start, the app keeps working with its built-in questions.
abstract final class EdgeAiRuntime {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> start() async {
    try {
      await FlutterEdgeAi.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
      );
      _ready = true;
    } on Object catch (e, s) {
      AppLogger.error(
        'On-device AI engine failed to start.',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// The catalog entry that backs each [ModelProfile].
  static InferenceVariant variantFor(ModelProfile profile) => switch (profile) {
    ModelProfile.balanced => LiteRtLmModels.qwen2_5_1_5bInstruct.q8Ekv4096,
    ModelProfile.quality => LiteRtLmModels.gemma4E2bIt.generic,
  };

  static String fileNameFor(ModelProfile profile) =>
      (variantFor(profile) as LiteRtLmVariant).file.installFilename;
}

/// [ModelManager] backed by `flutter_edge_ai` and the LiteRT-LM engine.
class EdgeAiModelManager implements ModelManager {
  EdgeAiModelManager({
    DeviceCapabilityChecker checker = const DeviceCapabilityChecker(),
  }) : _checker = checker;

  final DeviceCapabilityChecker _checker;
  final _controller = StreamController<ModelStatus>.broadcast();
  ModelStatus _current = const ModelNotInstalled();
  CancelToken? _token;

  @override
  ModelStatus get current => _current;

  @override
  Stream<ModelStatus> get status => _controller.stream;

  void _emit(ModelStatus next) {
    _current = next;
    _controller.add(next);
  }

  @override
  Future<void> refresh(ModelProfile profile) async {
    if (_current is ModelDownloading) return;
    final unsupported = await _unsupportedReason(profile);
    if (unsupported != null) {
      _emit(ModelUnsupported(unsupported));
      return;
    }
    try {
      final installed = await FlutterEdgeAi.isModelInstalled(
        EdgeAiRuntime.fileNameFor(profile),
      );
      _emit(installed ? const ModelInstalled() : const ModelNotInstalled());
    } on Object catch (e) {
      AppLogger.warning('Could not check the installed model.', e);
      _emit(const ModelNotInstalled());
    }
  }

  Future<String?> _unsupportedReason(ModelProfile profile) async {
    if (!EdgeAiRuntime.isReady) {
      return 'The on-device AI engine could not start on this phone.';
    }
    final capability = await _checker.check();
    if (!capability.supported) return capability.reason;
    final ram = capability.ramMb;
    if (ram != null && ram < profile.minRamGb * 900) {
      return '${profile.title} needs about ${profile.minRamGb} GB of memory. '
          'Try Balanced instead.';
    }
    return null;
  }

  @override
  Future<void> download(ModelProfile profile) async {
    if (_current is ModelDownloading) return;
    final unsupported = await _unsupportedReason(profile);
    if (unsupported != null) {
      _emit(ModelUnsupported(unsupported));
      return;
    }
    final token = _token = CancelToken();
    _emit(const ModelDownloading(0));
    try {
      await FlutterEdgeAi.installModelFromCatalog(
            EdgeAiRuntime.variantFor(profile),
          )
          .withProgress((p) => _emit(ModelDownloading(p.clamp(0, 100))))
          .withCancelToken(token)
          .install();
      _emit(const ModelInstalled());
    } on DownloadCancelledException {
      _emit(const ModelNotInstalled());
    } on DownloadException catch (e) {
      AppLogger.warning('Model download failed.', e);
      _emit(ModelFailed(_friendly(e.error)));
    } on Object catch (e, s) {
      AppLogger.error('Model install failed.', error: e, stackTrace: s);
      _emit(
        const ModelFailed('The download did not finish. Please try again.'),
      );
    } finally {
      _token = null;
    }
  }

  String _friendly(DownloadError error) => switch (error) {
    NetworkError() => 'No internet connection. Connect to Wi-Fi and try again.',
    ServerError() || RateLimitedError() =>
      'The download server is busy. Please try again later.',
    NotFoundError() =>
      'The model file was not found. Update the app and retry.',
    UnauthorizedError() ||
    ForbiddenError() => 'The model could not be downloaded without an account.',
    CanceledError() => 'The download was cancelled.',
    UnknownError() => 'The download did not finish. Please try again.',
  };

  @override
  void cancelDownload() => _token?.cancel('Cancelled by a grown-up');

  @override
  Future<void> delete(ModelProfile profile) async {
    try {
      await FlutterEdgeAi.uninstallModel(EdgeAiRuntime.fileNameFor(profile));
    } on Object catch (e) {
      AppLogger.warning('Could not delete the model.', e);
    }
    _emit(const ModelNotInstalled());
  }
}
