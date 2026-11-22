import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/services/natural_voice.dart';
import 'package:wonderly/core/services/speech_service.dart';

class _RecordingSpeech implements SpeechService {
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<Result<void>> speak(String text) async {
    spoken.add(text);
    return const Result.success(null);
  }

  @override
  Future<void> stop() async => stops++;
}

void main() {
  // All HTTP requests return 400 under the test binding, so no test here can
  // reach the network.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory base;
  late _RecordingSpeech system;
  late NaturalVoice voice;

  Directory modelDir() =>
      Directory('${base.path}/voices/${VoiceModel.kokoro.folder}');

  setUp(() {
    base = Directory.systemTemp.createTempSync('natural_voice_test');
    system = _RecordingSpeech();
    voice = NaturalVoice(fallback: system, baseDir: () async => base);
  });

  tearDown(() => base.deleteSync(recursive: true));

  group('NaturalVoice', () {
    test('starts not installed and reads with the system voice', () async {
      await voice.refresh();
      expect(voice.status.value.stage, VoiceStage.notInstalled);

      final result = await voice.speak('Hello there');
      expect(result.failureOrNull, isNull);
      expect(system.spoken, ['Hello there']);
    });

    test('notices a voice that is already installed', () async {
      modelDir()
        ..createSync(recursive: true)
        ..childFile('.complete').writeAsStringSync('ok');
      await voice.refresh();
      expect(voice.status.value.isReady, isTrue);
    });

    test('an unfinished install does not count as installed', () async {
      modelDir().createSync(recursive: true);
      await voice.refresh();
      expect(voice.status.value.stage, VoiceStage.notInstalled);
    });

    test('falls back to the system voice when the engine cannot run', () async {
      // The folder claims to be installed but holds no model files.
      modelDir()
        ..createSync(recursive: true)
        ..childFile('.complete').writeAsStringSync('ok');
      await voice.refresh();

      final result = await voice.speak('Still readable');
      expect(result.failureOrNull, isNull);
      expect(system.spoken, ['Still readable']);
    });

    test('a failed download ends in a clear, retryable state', () async {
      await voice.install();
      expect(voice.status.value.stage, VoiceStage.failed);
      expect(voice.status.value.message, contains('try again'));
      expect(modelDir().existsSync(), isFalse);
    });

    test('removing the voice deletes it and resets the status', () async {
      modelDir()
        ..createSync(recursive: true)
        ..childFile('.complete').writeAsStringSync('ok');
      await voice.refresh();

      await voice.remove();
      expect(modelDir().existsSync(), isFalse);
      expect(voice.status.value.stage, VoiceStage.notInstalled);
    });

    test('stop silences the system voice too', () async {
      await voice.stop();
      expect(system.stops, 1);
    });
  });
}

extension on Directory {
  File childFile(String name) => File('$path/$name');
}
