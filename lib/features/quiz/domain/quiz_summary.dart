import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';

/// One answered question, kept for the "Review answers" list.
class AnswerRecord extends Equatable {
  const AnswerRecord({
    required this.question,
    required this.correct,
    required this.correctLabel,
    this.chosenLabel,
  });

  final Question question;
  final bool correct;

  /// What the child picked, or `null` for drag-and-match questions.
  final String? chosenLabel;
  final String correctLabel;

  @override
  List<Object?> get props => [question.id, correct, chosenLabel, correctLabel];
}

/// Result of a finished quiz session, shown on the results screen.
class QuizSummary extends Equatable {
  const QuizSummary({
    required this.setId,
    required this.setTitle,
    required this.correct,
    required this.total,
    required this.seconds,
    required this.stars,
    required this.newBadges,
    required this.answers,
  });

  final String setId;
  final String setTitle;
  final int correct;
  final int total;
  final int seconds;
  final int stars;
  final List<BadgeId> newBadges;
  final List<AnswerRecord> answers;

  String get durationLabel {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  List<Object?> get props => [
    setId,
    setTitle,
    correct,
    total,
    seconds,
    stars,
    newBadges,
    answers,
  ];
}
