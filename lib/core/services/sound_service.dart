import 'package:audioplayers/audioplayers.dart';
import 'package:wonderly/core/utils/app_logger.dart';

/// Short sounds the app can play.
enum SoundEffect {
  correct('audio/correct.wav'),
  wrong('audio/wrong.wav'),
  tap('audio/tap.wav'),
  complete('audio/complete.wav'),
  badge('audio/badge.wav');

  const SoundEffect(this.asset);

  final String asset;
}

/// Plays effects and background music. Implementations never throw and honour
/// the user's sound settings.
abstract interface class SoundService {
  Future<void> play(SoundEffect effect);

  /// Starts or stops the music so it matches the Music setting.
  Future<void> syncMusic({required bool wanted});

  /// Pauses everything while the app is in the background.
  Future<void> pauseAll();

  Future<void> resumeMusic({required bool wanted});
}

/// [SoundService] built on `audioplayers`, using bundled synthesised audio.
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService({required bool Function() effectsEnabled})
    : _effectsEnabled = effectsEnabled;

  final bool Function() _effectsEnabled;
  AudioPlayer? _effects;
  AudioPlayer? _music;
  bool _musicPlaying = false;
  bool _contextSet = false;

  Future<void> _ensureContext() async {
    if (_contextSet) return;
    _contextSet = true;
    // Mix with other audio instead of stopping a parent's podcast.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
  }

  @override
  Future<void> play(SoundEffect effect) async {
    if (!_effectsEnabled()) return;
    try {
      await _ensureContext();
      var player = _effects;
      if (player == null) {
        player = _effects = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
      }
      await player.stop();
      await player.play(AssetSource(effect.asset), volume: 0.8);
    } on Exception catch (e) {
      AppLogger.warning('Could not play ${effect.name}.', e);
    }
  }

  @override
  Future<void> syncMusic({required bool wanted}) async {
    try {
      if (wanted && !_musicPlaying) {
        await _ensureContext();
        final player = _music ??= AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('audio/music.wav'), volume: 0.3);
        _musicPlaying = true;
      } else if (!wanted && _musicPlaying) {
        await _music?.stop();
        _musicPlaying = false;
      }
    } on Exception catch (e) {
      AppLogger.warning('Could not change the music.', e);
    }
  }

  @override
  Future<void> pauseAll() async {
    try {
      await _music?.pause();
      await _effects?.stop();
    } on Exception catch (e) {
      AppLogger.warning('Could not pause audio.', e);
    }
  }

  @override
  Future<void> resumeMusic({required bool wanted}) async {
    try {
      if (wanted && _musicPlaying) {
        await _music?.resume();
      } else {
        await syncMusic(wanted: wanted);
      }
    } on Exception catch (e) {
      AppLogger.warning('Could not resume the music.', e);
    }
  }
}
