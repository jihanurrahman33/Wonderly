import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/services/sound_service.dart';
import 'package:wonderly/features/ai/data/device_capability.dart';
import 'package:wonderly/features/ai/data/edge_ai_llm_client.dart';
import 'package:wonderly/features/ai/data/edge_ai_model_manager.dart';
import 'package:wonderly/features/ai/data/plus_device_status.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';

import '../../helpers/fake_ai.dart';

/// These run on the host machine, where there is no phone engine, audio output
/// or battery. They prove every platform wrapper degrades gracefully instead of
/// throwing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('platform wrappers degrade gracefully', () {
    test('device capability reports unsupported hosts', () async {
      final result = await const DeviceCapabilityChecker().check();
      expect(result.supported, isFalse);
      expect(result.reason, contains('Android and iOS'));
    });

    test('model manager reports an engine that did not start', () async {
      final manager = EdgeAiModelManager();
      final seen = <ModelStatus>[];
      final sub = manager.status.listen(seen.add);
      await manager.refresh(ModelProfile.balanced);
      await pumpEventQueue();
      expect(manager.current, isA<ModelUnsupported>());
      expect(seen.single, isA<ModelUnsupported>());

      await manager.download(ModelProfile.balanced);
      expect(manager.current, isA<ModelUnsupported>());
      manager.cancelDownload();
      await sub.cancel();
    });

    test('every profile maps to a downloadable catalog file', () {
      for (final profile in ModelProfile.values) {
        final name = EdgeAiRuntime.fileNameFor(profile);
        expect(name, endsWith('.litertlm'));
        expect(EdgeAiRuntime.variantFor(profile), isNotNull);
      }
    });

    test('llm client refuses politely when no model is installed', () async {
      final client = EdgeAiLlmClient(FakeModelManager());
      expect(client.isReady, isFalse);
      final reply = await client.complete(system: 's', user: 'u');
      expect(reply.failureOrNull?.message, contains('not installed'));
      await client.release();
    });

    test(
      'llm client reports engine failures as failures, never exceptions',
      () async {
        final client = EdgeAiLlmClient(
          FakeModelManager(const ModelInstalled()),
        );
        expect(client.isReady, isTrue);
        final reply = await client.complete(system: 's', user: 'u');
        expect(reply.failureOrNull, isNotNull);
      },
    );

    test('device status falls back safely without plugins', () async {
      final status = PlusDeviceStatus();
      expect(await status.isOnUnmeteredNetwork(), isFalse);
      expect(await status.isBatteryLow(), isFalse);
    });

    test(
      'sound service never throws and respects the effects setting',
      () async {
        final off = AudioplayersSoundService(effectsEnabled: () => false);
        await off.play(SoundEffect.correct);

        final on = AudioplayersSoundService(effectsEnabled: () => true);
        await on.play(SoundEffect.correct);
        await on.syncMusic(wanted: true);
        await on.pauseAll();
        await on.resumeMusic(wanted: true);
        await on.syncMusic(wanted: false);
      },
    );

    test('each sound effect points at a bundled file', () {
      for (final e in SoundEffect.values) {
        expect(e.asset, startsWith('audio/'));
        expect(e.asset, endsWith('.wav'));
      }
    });
  });
}
