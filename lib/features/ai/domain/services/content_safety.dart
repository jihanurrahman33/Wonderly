/// Child-safety gate for text written by a language model.
///
/// It is deliberately strict: anything doubtful is rejected, because a
/// rejected question only costs one more generation.
class ContentSafety {
  const ContentSafety();

  static const _blocked = {
    'kill',
    'killed',
    'killing',
    'die',
    'dies',
    'dead',
    'death',
    'murder',
    'blood',
    'bloody',
    'gun',
    'guns',
    'shoot',
    'shot',
    'weapon',
    'bomb',
    'knife',
    'war',
    'hate',
    'stupid',
    'dumb',
    'idiot',
    'sex',
    'sexy',
    'nude',
    'naked',
    'drug',
    'drugs',
    'alcohol',
    'beer',
    'wine',
    'drunk',
    'cigarette',
    'smoke',
    'smoking',
    'suicide',
    'damn',
    'hell',
    'crap',
    'fight',
    'attack',
    'hurt',
    'poison',
    'gamble',
    'casino',
    'http',
    'https',
    'www',
    'email',
    'password',
  };

  static final _allowed = RegExp(r"^[A-Za-z0-9 .,?!'’\-:;()%+×÷=/&\n]+$");

  /// Returns why [text] is unsafe, or `null` when it is fine.
  String? check(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'empty text';
    if (trimmed.length > 220) return 'text too long';
    if (!_allowed.hasMatch(trimmed)) return 'unexpected characters';
    for (final word in trimmed.toLowerCase().split(RegExp(r'[^a-z]+'))) {
      if (_blocked.contains(word)) return 'blocked word "$word"';
    }
    return null;
  }
}
