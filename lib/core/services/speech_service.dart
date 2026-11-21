import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/app_logger.dart';

/// Reads text aloud. Implementations must never throw.
abstract interface class SpeechService {
  Future<Result<void>> speak(String text);

  Future<void> stop();
}

/// Offline text to speech using the device's built-in voices.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.1);
    _configured = true;
  }

  @override
  Future<Result<void>> speak(String text) async {
    try {
      await _configure();
      await _tts.stop();
      await _tts.speak(text);
      return const Result.success(null);
    } on PlatformException catch (e) {
      AppLogger.warning('Text to speech failed.', e);
      return const Result.failure(
        PlatformFailure('Read aloud is unavailable.'),
      );
    } on MissingPluginException catch (e) {
      AppLogger.warning('Text to speech plugin missing.', e);
      return const Result.failure(
        PlatformFailure('Read aloud is unavailable.'),
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on PlatformException catch (e) {
      AppLogger.warning('Could not stop speech.', e);
    } on MissingPluginException catch (e) {
      AppLogger.warning('Text to speech plugin missing.', e);
    }
  }
}
