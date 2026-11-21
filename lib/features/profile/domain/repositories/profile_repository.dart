import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';

/// Persistence contract for the learners on this device.
abstract interface class ProfileRepository {
  /// Loads the roster. Empty before onboarding is complete.
  Future<Result<LearnerRoster>> load();

  /// Atomically transforms and persists the roster.
  Future<Result<LearnerRoster>> update(
    LearnerRoster Function(LearnerRoster current) transform,
  );
}
