import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';

/// Persistence contract for the active learner profile.
abstract interface class ProfileRepository {
  /// Loads the saved profile, or `null` before onboarding is complete.
  Future<Result<LearnerProfile?>> load();

  /// Saves [profile], replacing any existing one.
  Future<Result<LearnerProfile>> save(LearnerProfile profile);
}
