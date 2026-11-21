import 'package:wonderly/features/learning/domain/entities/question.dart';

/// Safety gate: a question reaches a child only if it passes these checks.
///
/// Mirrors the validator that generated content must also pass.
class ValidateQuestion {
  const ValidateQuestion();

  static const maxPromptWords = 15;

  /// Returns the reason a question is invalid, or `null` when it is valid.
  String? call(Question question) {
    if (question.id.trim().isEmpty) return 'missing id';
    final prompt = question.prompt.trim();
    if (prompt.isEmpty) return 'empty prompt';
    if (prompt.split(RegExp(r'\s+')).length > maxPromptWords) {
      return 'prompt longer than $maxPromptWords words';
    }
    return switch (question) {
      ChoiceQuestion(:final options, :final answerIndex) => _choice(
        options.map((o) => o.label).toList(),
        answerIndex,
      ),
      PatternQuestion(:final options, :final answerIndex, :final sequence) =>
        sequence.length < 2
            ? 'pattern needs at least 2 items'
            : _choice(options, answerIndex),
      ShapeMatchQuestion(:final shapes) =>
        shapes.length < 2 || shapes.toSet().length != shapes.length
            ? 'shape match needs 2+ distinct shapes'
            : null,
    };
  }

  String? _choice(List<String> labels, int answerIndex) {
    if (labels.length < 2) return 'needs at least 2 options';
    if (labels.any((l) => l.trim().isEmpty)) return 'blank option';
    if (labels.toSet().length != labels.length) return 'duplicate options';
    if (answerIndex < 0 || answerIndex >= labels.length) {
      return 'answer index out of range';
    }
    return null;
  }
}
