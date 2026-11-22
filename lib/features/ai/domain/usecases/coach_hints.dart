import 'dart:async';

import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/domain/services/content_safety.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';

/// Writes short, kind hints and explanations for a question with the on-device
/// model.
///
/// The model never decides what is correct: it is told the right answer and
/// only has to put it in friendly words. Every reply must pass [ContentSafety],
/// must not give the answer away when it is a hint, and must agree with the
/// known answer when it is an explanation. Anything else returns `null`, and
/// the caller keeps the built-in text, so a child is never shown doubtful
/// words.
class CoachHints {
  CoachHints({
    required LlmClient llm,
    ContentSafety safety = const ContentSafety(),
    Duration timeout = const Duration(seconds: 12),
    bool Function()? isEnabled,
  }) : _llm = llm,
       _safety = safety,
       _timeout = timeout,
       _isEnabled = isEnabled ?? (() => true);

  static const _system =
      'You are Wonderly, a warm and cheerful buddy for children aged 6 to 10. '
      'Write one or two short, simple sentences. Use easy words and no '
      'markdown, lists, emojis or quotation marks.';

  final LlmClient _llm;
  final ContentSafety _safety;
  final Duration _timeout;

  /// Lets a grown-up switch the AI off in settings.
  final bool Function() _isEnabled;
  final _cache = <String, String?>{};

  bool get available => _isEnabled() && _llm.isReady;

  /// A nudge that helps the child think without naming the answer.
  Future<String?> hint(Question question) async {
    if (question is! ChoiceQuestion) return null;
    final answer = question.options[question.answerIndex].label;
    final options = question.options.map((o) => o.label).join(', ');
    final text = await _ask(
      'hint:${question.id}',
      'Question: ${question.prompt}\n'
          'Choices: $options\n'
          'Write a short hint that helps the child work it out. Do NOT say '
          'the answer.',
    );
    if (text == null) return null;
    if (_mentions(text, answer)) {
      AppLogger.info('Coach hint dropped (gives the answer away): $text');
      return null;
    }
    return text;
  }

  /// A friendly reason why [question]'s answer is right, aimed at what the
  /// child picked ([chosenIndex], or `null` when unknown).
  Future<String?> explain(Question question, {int? chosenIndex}) async {
    if (question is! ChoiceQuestion) return null;
    final answer = question.options[question.answerIndex].label;
    final wrong =
        chosenIndex != null &&
        chosenIndex >= 0 &&
        chosenIndex < question.options.length &&
        chosenIndex != question.answerIndex;
    final chosen = wrong ? question.options[chosenIndex].label : null;
    final task = wrong
        ? 'The child picked "$chosen", which is not right. Kindly explain why '
              '"$answer" is the right answer, without making them feel bad.'
        : 'The child answered correctly. Explain in a fun way why "$answer" '
              'is right.';
    final text = await _ask(
      'explain:${question.id}:${chosen ?? 'right'}',
      'Question: ${question.prompt}\nCorrect answer: $answer\n$task',
    );
    // An explanation that never names the right answer may contradict it.
    if (text == null) return null;
    if (!_mentions(text, answer)) {
      AppLogger.info('Coach explanation dropped (names no answer): $text');
      return null;
    }
    return text;
  }

  Future<String?> _ask(String key, String user) async {
    if (_cache.containsKey(key)) return _cache[key];
    if (!_llm.isReady) return null;
    String? clean;
    try {
      final result = await _llm
          .complete(
            system: _system,
            user: user,
            maxOutputTokens: 90,
            temperature: 0.4,
          )
          .timeout(_timeout);
      clean = _clean(result.valueOrNull);
    } on TimeoutException {
      return null;
    }
    _cache[key] = clean;
    return clean;
  }

  String? _clean(String? raw) {
    if (raw == null) return null;
    final text = raw
        .replaceAll(RegExp('[—–]'), '-')
        .replaceAll(RegExp('[“”"*_`#]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final problem = _safety.check(text);
    if (problem != null) {
      AppLogger.info('Coach reply dropped ($problem): $text');
      return null;
    }
    return text;
  }

  static bool _mentions(String text, String label) {
    final pattern = RegExp(
      '(?<![A-Za-z0-9])${RegExp.escape(label.trim())}(?![A-Za-z0-9])',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }
}
