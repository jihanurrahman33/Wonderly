import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';
import 'package:wonderly/features/progress/domain/services/progress_reducer.dart';

/// Adds played seconds to today's total.
class RecordPlayTime {
  const RecordPlayTime(this._repository, this._clock);

  final ProgressRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(int seconds) async {
    final now = _clock.now();
    final result = await _repository.update(
      (current) => ProgressReducer.applySeconds(current, seconds, now),
    );
    return result.fold(
      onSuccess: (_) => const Result.success(null),
      onFailure: Result.failure,
    );
  }
}
