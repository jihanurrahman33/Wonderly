import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

/// One answer choice. [art] is an optional illustration key.
class AnswerOption extends Equatable {
  const AnswerOption({required this.label, this.art});

  final String label;
  final String? art;

  @override
  List<Object?> get props => [label, art];
}

/// How a [ChoiceQuestion] lays out its options.
enum ChoiceLayout { pictureGrid, textList }

/// A question the child answers during a quiz.
///
/// The hierarchy is sealed so every renderer and rule must handle each kind.
sealed class Question extends Equatable {
  const Question({
    required this.id,
    required this.subject,
    required this.setId,
    required this.prompt,
    this.hint,
    this.fact,
  });

  final String id;
  final Subject subject;
  final String setId;
  final String prompt;

  /// Shown when the child taps Hint.
  final String? hint;

  /// Short explanation shown after answering.
  final String? fact;
}

/// Pick the single right option out of several.
class ChoiceQuestion extends Question {
  const ChoiceQuestion({
    required super.id,
    required super.subject,
    required super.setId,
    required super.prompt,
    required this.options,
    required this.answerIndex,
    this.layout = ChoiceLayout.pictureGrid,
    this.scene,
    super.hint,
    super.fact,
  });

  final List<AnswerOption> options;
  final int answerIndex;
  final ChoiceLayout layout;

  /// Optional illustration keys shown above the prompt (for example plants).
  final List<String>? scene;

  bool isCorrect(int index) => index == answerIndex;

  @override
  List<Object?> get props => [
    id,
    subject,
    setId,
    prompt,
    options,
    answerIndex,
    layout,
    scene,
  ];
}

/// Complete a repeating sequence of shapes.
class PatternQuestion extends Question {
  const PatternQuestion({
    required super.id,
    required super.subject,
    required super.setId,
    required super.prompt,
    required this.sequence,
    required this.options,
    required this.answerIndex,
    super.hint,
    super.fact,
  });

  final List<String> sequence;
  final List<String> options;
  final int answerIndex;

  bool isCorrect(int index) => index == answerIndex;

  @override
  List<Object?> get props => [
    id,
    subject,
    setId,
    prompt,
    sequence,
    options,
    answerIndex,
  ];
}

/// Drag each shape onto its matching outline.
class ShapeMatchQuestion extends Question {
  const ShapeMatchQuestion({
    required super.id,
    required super.subject,
    required super.setId,
    required super.prompt,
    required this.shapes,
    super.hint,
    super.fact,
  });

  /// Shape keys; each is both a draggable piece and a target slot.
  final List<String> shapes;

  @override
  List<Object?> get props => [id, subject, setId, prompt, shapes];
}
