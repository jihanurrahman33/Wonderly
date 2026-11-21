import 'dart:async';

import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/services/sound_service.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/domain/services/device_status.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/domain/services/model_manager.dart';

/// Scripted [LlmClient]: replies come from [reply], one call at a time.
class FakeLlm implements LlmClient {
  FakeLlm({this.ready = true, this.reply});

  bool ready;

  /// Computes the reply for a prompt. Return `null` to simulate a failure.
  String? Function(String system, String user)? reply;

  final List<String> users = [];
  int released = 0;

  @override
  bool get isReady => ready;

  @override
  Future<Result<String>> complete({
    required String system,
    required String user,
    Map<String, Object?>? jsonSchema,
    int maxOutputTokens = 400,
    double temperature = 0.7,
  }) async {
    users.add(user);
    final text = reply?.call(system, user);
    if (text == null) {
      return const Result.failure(PlatformFailure('fake failure'));
    }
    return Result.success(text);
  }

  @override
  Future<void> release() async => released++;
}

/// Controllable [ModelManager].
class FakeModelManager implements ModelManager {
  FakeModelManager([ModelStatus initial = const ModelNotInstalled()])
    : _current = initial;

  final _controller = StreamController<ModelStatus>.broadcast();
  ModelStatus _current;
  int downloads = 0;
  int cancels = 0;
  int deletes = 0;

  @override
  ModelStatus get current => _current;

  @override
  Stream<ModelStatus> get status => _controller.stream;

  void set(ModelStatus next) {
    _current = next;
    _controller.add(next);
  }

  @override
  Future<void> refresh(ModelProfile profile) async => set(_current);

  @override
  Future<void> download(ModelProfile profile) async {
    downloads++;
    set(const ModelDownloading(10));
  }

  @override
  void cancelDownload() {
    cancels++;
    set(const ModelNotInstalled());
  }

  @override
  Future<void> delete(ModelProfile profile) async {
    deletes++;
    set(const ModelNotInstalled());
  }
}

class FakeDeviceStatus implements DeviceStatus {
  FakeDeviceStatus({this.wifi = true, this.lowBattery = false});

  bool wifi;
  bool lowBattery;

  @override
  Future<bool> isBatteryLow() async => lowBattery;

  @override
  Future<bool> isOnUnmeteredNetwork() async => wifi;
}

class FakeSound implements SoundService {
  final List<SoundEffect> played = [];
  bool? music;

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> play(SoundEffect effect) async => played.add(effect);

  @override
  Future<void> resumeMusic({required bool wanted}) async {}

  @override
  Future<void> syncMusic({required bool wanted}) async => music = wanted;
}

/// A well-formed model reply for the question generator.
String questionReply({
  String question = 'Which animal says moo?',
  List<String> options = const ['Cow', 'Dog', 'Cat', 'Duck'],
  int answer = 0,
  String hint = 'It lives on a farm.',
  String fact = 'Cows say moo and give us milk.',
}) {
  final quoted = options.map((o) => '"$o"').join(', ');
  return '{"question": "$question", "options": [$quoted], "answer": $answer, '
      '"hint": "$hint", "fact": "$fact"}';
}
