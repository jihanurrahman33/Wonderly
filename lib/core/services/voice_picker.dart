/// Chooses the most natural-sounding offline voice from the ones a device
/// reports, so read-aloud sounds like a person and not a robot.
///
/// The system default voice is often the oldest, most robotic one. Newer
/// "enhanced" and "premium" voices (iOS and macOS) and local neural voices
/// (Android) sound far better, so they are ranked first. Novelty voices are
/// never picked.
abstract final class VoicePicker {
  /// macOS novelty voices: fun for demos, wrong for teaching.
  static const _novelty = {
    'albert',
    'bad news',
    'bahh',
    'bells',
    'boing',
    'bubbles',
    'cellos',
    'good news',
    'jester',
    'junior',
    'organ',
    'superstar',
    'trinoids',
    'whisper',
    'wobble',
    'zarvox',
    'fred',
    'ralph',
    'kathy',
  };

  /// Older compact voices that sound flat next to the voices above.
  static const _compact = {
    'eddy',
    'flo',
    'grandma',
    'grandpa',
    'reed',
    'rocko',
    'sandy',
    'shelley',
  };

  /// Warm, clear voices that suit young listeners.
  static const _warm = {
    'ava',
    'allison',
    'samantha',
    'nicky',
    'zoe',
    'susan',
    'joelle',
    'noelle',
    'evan',
    'tom',
    'nathan',
  };

  /// The best voice in [voices] (each a map with `name`, `locale`, and when
  /// the platform has them `quality` and `identifier`), or `null` when none is
  /// English.
  static Map<String, String>? best(Iterable<Object?> voices) {
    Map<String, String>? bestVoice;
    var bestScore = -1 << 30;
    for (final raw in voices) {
      if (raw is! Map) continue;
      final voice = {
        for (final e in raw.entries) e.key.toString(): e.value.toString(),
      };
      final score = _score(voice);
      if (score != null && score > bestScore) {
        bestScore = score;
        bestVoice = voice;
      }
    }
    return bestVoice;
  }

  /// Higher is better; `null` rules the voice out.
  static int? _score(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').replaceAll('_', '-').toLowerCase();
    if (!locale.startsWith('en')) return null;
    final name = (voice['name'] ?? '').toLowerCase();
    final id = (voice['identifier'] ?? '').toLowerCase();
    final quality = (voice['quality'] ?? '').toLowerCase();
    final haystack = '$name $id';
    final firstName = name.split(RegExp(r'[\s(]')).first;

    if (_novelty.contains(firstName) || _novelty.contains(name)) return null;
    // Voices that need the internet break the offline promise.
    if (haystack.contains('network')) return null;

    var score = 0;
    if (locale == 'en-us') score += 100;
    if (quality.contains('premium') || haystack.contains('premium')) {
      score += 400;
    } else if (quality.contains('enhanced') || haystack.contains('enhanced')) {
      score += 300;
    }
    if (haystack.contains('siri')) score += 350;
    if (haystack.contains('neural') || haystack.contains('natural')) {
      score += 200;
    }
    if (haystack.contains('local')) score += 20;
    if (_warm.contains(firstName)) score += 60;
    if (_compact.contains(firstName)) score -= 150;
    return score;
  }
}
