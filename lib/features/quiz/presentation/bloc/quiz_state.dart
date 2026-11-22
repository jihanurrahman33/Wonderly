import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';
import 'package:wonderly/features/quiz/domain/quiz_summary.dart';
import 'package:wonderly/features/settings/domain/services/play_guard.dart';

enum QuizStatus { loading, playing, blocked, finished, failed }

class QuizState extends Equatable {
  const QuizState({
    this.status = QuizStatus.loading,
    this.set,
    this.index = 0,
    this.selected,
    this.revealed = false,
    this.lastCorrect,
    this.placed = const {},
    this.hintVisible = false,
    this.aiHint,
    this.aiHintLoading = false,
    this.aiExplanation,
    this.aiExplanationLoading = false,
    this.paused = false,
    this.correctCount = 0,
    this.answers = const [],
    this.starsEarned = 0,
    this.lastStars = 0,
    this.newBadges = const [],
    this.seconds = 0,
    this.blockReason,
    this.summary,
    this.saveFailed = false,
  });

  final QuizStatus status;
  final QuizSet? set;
  final int index;

  /// Chosen option for choice and pattern questions.
  final int? selected;

  /// Whether the answer for the current question has been checked.
  final bool revealed;
  final bool? lastCorrect;

  /// Shapes already matched on a drag question.
  final Set<String> placed;
  final bool hintVisible;

  /// Model-written hint for this question, once it arrives.
  final String? aiHint;
  final bool aiHintLoading;

  /// Model-written explanation shown after the answer is checked.
  final String? aiExplanation;
  final bool aiExplanationLoading;
  final bool paused;
  final int correctCount;
  final List<AnswerRecord> answers;
  final int starsEarned;

  /// Stars the most recent answer earned (shown in the feedback panel).
  final int lastStars;
  final List<BadgeId> newBadges;
  final int seconds;
  final BreakReason? blockReason;
  final QuizSummary? summary;

  /// Set when progress could not be saved, so the UI can tell a grown-up.
  final bool saveFailed;

  Question? get question {
    final s = set;
    if (s == null || index < 0 || index >= s.length) return null;
    return s.questions[index];
  }

  int get total => set?.length ?? 0;

  /// Whether Next may be pressed for the current question.
  bool get canAdvance => switch (question) {
    ChoiceQuestion() || PatternQuestion() => selected != null,
    ShapeMatchQuestion(:final shapes) => placed.length == shapes.length,
    null => false,
  };

  QuizState copyWith({
    QuizStatus? status,
    QuizSet? set,
    int? index,
    int? Function()? selected,
    bool? revealed,
    bool? Function()? lastCorrect,
    Set<String>? placed,
    bool? hintVisible,
    String? Function()? aiHint,
    bool? aiHintLoading,
    String? Function()? aiExplanation,
    bool? aiExplanationLoading,
    bool? paused,
    int? correctCount,
    List<AnswerRecord>? answers,
    int? starsEarned,
    int? lastStars,
    List<BadgeId>? newBadges,
    int? seconds,
    BreakReason? blockReason,
    QuizSummary? summary,
    bool? saveFailed,
  }) {
    return QuizState(
      status: status ?? this.status,
      set: set ?? this.set,
      index: index ?? this.index,
      selected: selected != null ? selected() : this.selected,
      revealed: revealed ?? this.revealed,
      lastCorrect: lastCorrect != null ? lastCorrect() : this.lastCorrect,
      placed: placed ?? this.placed,
      hintVisible: hintVisible ?? this.hintVisible,
      aiHint: aiHint != null ? aiHint() : this.aiHint,
      aiHintLoading: aiHintLoading ?? this.aiHintLoading,
      aiExplanation: aiExplanation != null
          ? aiExplanation()
          : this.aiExplanation,
      aiExplanationLoading: aiExplanationLoading ?? this.aiExplanationLoading,
      paused: paused ?? this.paused,
      correctCount: correctCount ?? this.correctCount,
      answers: answers ?? this.answers,
      starsEarned: starsEarned ?? this.starsEarned,
      lastStars: lastStars ?? this.lastStars,
      newBadges: newBadges ?? this.newBadges,
      seconds: seconds ?? this.seconds,
      blockReason: blockReason ?? this.blockReason,
      summary: summary ?? this.summary,
      saveFailed: saveFailed ?? this.saveFailed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    set,
    index,
    selected,
    revealed,
    lastCorrect,
    placed,
    hintVisible,
    aiHint,
    aiHintLoading,
    aiExplanation,
    aiExplanationLoading,
    paused,
    correctCount,
    answers,
    starsEarned,
    lastStars,
    newBadges,
    seconds,
    blockReason,
    summary,
    saveFailed,
  ];
}
