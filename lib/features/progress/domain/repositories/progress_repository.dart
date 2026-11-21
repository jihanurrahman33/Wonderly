import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';

/// Persistence contract for learning progress.
abstract interface class ProgressRepository {
  /// Emits the latest progress after every successful change.
  Stream<LearnerProgress> watch();

  Future<Result<LearnerProgress>> load();

  /// Switches to the progress of [learnerId] and emits it on [watch].
  Future<void> bindTo(String learnerId);

  /// Erases the progress stored for [learnerId].
  Future<void> deleteFor(String learnerId);

  /// Atomically transforms the stored progress and persists the result.
  Future<Result<LearnerProgress>> update(
    LearnerProgress Function(LearnerProgress current) transform,
  );
}
