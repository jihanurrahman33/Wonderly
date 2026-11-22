import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/services/voice_picker.dart';
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
    // A natural pace and pitch: raising the pitch is what made the old setup
    // sound like a toy. The voice itself matters most, so pick the best one.
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
    try {
      final voice = VoicePicker.best(
        (await _tts.getVoices as List<Object?>?) ?? const [],
      );
      if (voice != null) {
        await _tts.setVoice({
          'name': voice['name'] ?? '',
          'locale': voice['locale'] ?? 'en-US',
          if (voice['identifier'] != null) 'identifier': voice['identifier']!,
        });
        AppLogger.info(
          'Read aloud voice: ${voice['name']} (${voice['quality'] ?? 'n/a'}).',
        );
      }
    } on Object catch (e) {
      // Keep the system voice: speech still works, just less naturally.
      AppLogger.warning('Could not choose a read aloud voice.', e);
    }
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
