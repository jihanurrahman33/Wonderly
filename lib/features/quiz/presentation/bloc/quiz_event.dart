import 'package:equatable/equatable.dart';

sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => const [];
}

/// Opens quiz set [setId] and resumes where the child left off.
final class QuizStarted extends QuizEvent {
  const QuizStarted(this.setId);

  final String setId;

  @override
  List<Object?> get props => [setId];
}

/// The child tapped answer [index] (choice and pattern questions).
final class QuizOptionSelected extends QuizEvent {
  const QuizOptionSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// The child dropped [shape] on its matching outline.
final class QuizShapePlaced extends QuizEvent {
  const QuizShapePlaced(this.shape);

  final String shape;

  @override
  List<Object?> get props => [shape];
}

/// The child pressed Next (checks the answer, then moves on).
final class QuizNextPressed extends QuizEvent {
  const QuizNextPressed();
}

/// Show or hide the hint for the current question.
final class QuizHintToggled extends QuizEvent {
  const QuizHintToggled();
}

/// One second of play time passed.
final class QuizTicked extends QuizEvent {
  const QuizTicked();
}

/// The app went to the background or came back.
final class QuizLifecycleChanged extends QuizEvent {
  const QuizLifecycleChanged({required this.active});

  final bool active;

  @override
  List<Object?> get props => [active];
}
