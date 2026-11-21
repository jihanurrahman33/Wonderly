import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';
import 'package:wonderly/features/progress/domain/services/progress_reducer.dart';

/// Persists the effect of one answered question.
class RecordAnswer {
  const RecordAnswer(this._repository, this._clock);

  final ProgressRepository _repository;
  final Clock _clock;

  Future<Result<AnswerOutcome>> call({
    required Question question,
    required int setLength,
    required bool correct,
  }) async {
    AnswerOutcome? outcome;
    final now = _clock.now();
    final result = await _repository.update((current) {
      final (next, o) = ProgressReducer.applyAnswer(
        current,
        questionId: question.id,
        setId: question.setId,
        subject: question.subject,
        setLength: setLength,
        correct: correct,
        now: now,
      );
      outcome = o;
      return next;
    });
    return result.fold(
      onSuccess: (_) => Result.success(
        outcome ??
            const AnswerOutcome(
              starsGained: 0,
              completedSet: false,
              newBadges: [],
            ),
      ),
      onFailure: Result.failure,
    );
  }
}
