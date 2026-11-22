import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/services/speech_service.dart';
import 'package:wonderly/core/utils/app_logger.dart';

enum VoiceStage { notInstalled, downloading, installing, ready, failed }

/// Where the natural voice is, for the grown-ups setup card.
@immutable
class VoiceStatus {
  const VoiceStatus(this.stage, {this.percent = 0, this.message});

  final VoiceStage stage;
  final int percent;
  final String? message;

  bool get isReady => stage == VoiceStage.ready;
  bool get isBusy =>
      stage == VoiceStage.downloading || stage == VoiceStage.installing;
}

/// The neural voice the app downloads: Kokoro (82M, Apache 2.0), run on the
/// device with sherpa-onnx. It sounded clearly more human than the smaller
/// Piper voice we also tried.
class VoiceModel {
  const VoiceModel._();

  static const kokoro = VoiceModel._();

  /// Folder name inside the downloaded archive.
  String get folder => 'kokoro-int8-multi-lang-v1_1';

  String get sizeLabel => 'about 150 MB';

  /// Which of the model's speakers reads aloud.
  int get sid => 0;

  double get speed => 1.0;

  String get url =>
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/'
      '$folder.tar.bz2';

  sherpa.OfflineTtsModelConfig config(String d) => sherpa.OfflineTtsModelConfig(
    kokoro: sherpa.OfflineTtsKokoroModelConfig(
      model: '$d/model.int8.onnx',
      voices: '$d/voices.bin',
      tokens: '$d/tokens.txt',
      dataDir: '$d/espeak-ng-data',
      lexicon: '$d/lexicon-us-en.txt',
    ),
    numThreads: 2,
  );
}

/// A human-sounding neural voice (run on the device with sherpa-onnx).
///
/// It downloads once, after a grown-up asks for it, then works fully offline.
/// Until it is installed, or if anything goes wrong, reading aloud falls back
/// to the system voice, so a child always hears something.
class NaturalVoice implements SpeechService {
  NaturalVoice({
    required SpeechService fallback,
    this.model = VoiceModel.kokoro,
    Future<Directory> Function()? baseDir,
    HttpClient Function()? httpClient,
  }) : _fallback = fallback,
       _baseDir = baseDir ?? getApplicationSupportDirectory,
       _httpClient = httpClient ?? HttpClient.new;

  static const _marker = '.complete';

  final VoiceModel model;

  final SpeechService _fallback;
  final Future<Directory> Function() _baseDir;
  final HttpClient Function() _httpClient;

  /// Drives the setup card.
  final ValueNotifier<VoiceStatus> status = ValueNotifier(
    const VoiceStatus(VoiceStage.notInstalled),
  );

  AudioPlayer? _player;
  sherpa.OfflineTts? _engine;
  bool _bindingsReady = false;
  bool _cancel = false;

  Future<Directory> _modelDir() async =>
      Directory('${(await _baseDir()).path}/voices/${model.folder}');

  /// Looks on disk and updates [status].
  Future<void> refresh() async {
    if (status.value.isBusy) return;
    try {
      final dir = await _modelDir();
      final ready = File('${dir.path}/$_marker').existsSync();
      status.value = VoiceStatus(
        ready ? VoiceStage.ready : VoiceStage.notInstalled,
      );
    } on Object catch (e) {
      AppLogger.warning('Could not check the natural voice.', e);
    }
  }

  /// Downloads and unpacks the voice (about 65 MB).
  Future<void> install() async {
    if (status.value.isBusy || status.value.isReady) return;
    _cancel = false;
    status.value = const VoiceStatus(VoiceStage.downloading);
    final temp = File('${Directory.systemTemp.path}/${model.folder}.tar.bz2');
    try {
      await _download(temp);
      if (_cancel) return _reset();
      status.value = const VoiceStatus(VoiceStage.installing);
      final dir = await _modelDir();
      await Isolate.run(() => _unpack(temp.path, dir.parent.path));
      File('${dir.path}/$_marker').writeAsStringSync('ok');
      status.value = const VoiceStatus(VoiceStage.ready);
    } on Object catch (e) {
      AppLogger.warning('Natural voice install failed.', e);
      status.value = const VoiceStatus(
        VoiceStage.failed,
        message: 'The voice did not finish downloading. Please try again.',
      );
    } finally {
      if (temp.existsSync()) temp.deleteSync();
    }
  }

  void cancelInstall() => _cancel = true;

  void _reset() => status.value = const VoiceStatus(VoiceStage.notInstalled);

  Future<void> _download(File target) async {
    final client = _httpClient();
    try {
      final request = await client.getUrl(Uri.parse(model.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Voice download returned ${response.statusCode}.');
      }
      final total = response.contentLength;
      final sink = target.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          if (_cancel) break;
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final percent = (received * 100 ~/ total).clamp(0, 100);
            if (percent != status.value.percent) {
              status.value = VoiceStatus(
                VoiceStage.downloading,
                percent: percent,
              );
            }
          }
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Runs in a background isolate: unpacking is heavy.
  static void _unpack(String archivePath, String destination) {
    final bytes = File(archivePath).readAsBytesSync();
    final tar = TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes));
    for (final entry in tar) {
      final path = '$destination/${entry.name}';
      if (entry.isFile) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(entry.content);
      } else {
        Directory(path).createSync(recursive: true);
      }
    }
  }

  /// Removes the voice to free its space.
  Future<void> remove() async {
    await stop();
    _engine?.free();
    _engine = null;
    try {
      final dir = await _modelDir();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } on Object catch (e) {
      AppLogger.warning('Could not remove the natural voice.', e);
    }
    _reset();
  }

  sherpa.OfflineTts _engineFor(String dir) {
    if (!_bindingsReady) {
      sherpa.initBindings();
      _bindingsReady = true;
    }
    return _engine ??= sherpa.OfflineTts(
      sherpa.OfflineTtsConfig(model: model.config(dir)),
    );
  }

  @override
  Future<Result<void>> speak(String text) async {
    if (!status.value.isReady) return _fallback.speak(text);
    try {
      final dir = await _modelDir();
      final audio = _engineFor(dir.path)
          .generate(text: text, sid: model.sid, speed: model.speed);
      if (audio.samples.isEmpty) {
        // The engine could not load the model: drop it so the next try
        // starts clean instead of reusing a dead engine.
        _engine?.free();
        _engine = null;
        return await _fallback.speak(text);
      }
      final wav = File('${Directory.systemTemp.path}/wonderly_voice.wav');
      sherpa.writeWave(
        filename: wav.path,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      await _fallback.stop();
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(DeviceFileSource(wav.path));
      return const Result.success(null);
    } on Object catch (e, s) {
      AppLogger.error('Natural voice failed.', error: e, stackTrace: s);
      final fallback = await _fallback.speak(text);
      return fallback.failureOrNull == null
          ? fallback
          : const Result.failure(PlatformFailure('Read aloud is unavailable.'));
    }
  }

  @override
  Future<void> stop() async {
    await _fallback.stop();
    try {
      await _player?.stop();
    } on Object catch (e) {
      AppLogger.warning('Could not stop the natural voice.', e);
    }
  }
}
