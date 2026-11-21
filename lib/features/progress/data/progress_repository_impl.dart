import 'package:wonderly/core/storage/json_value_repository.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';

/// Per-learner progress. Each learner has their own document; the learner who
/// predates multiple learners keeps the original key so nothing is lost.
class ProgressRepositoryImpl extends JsonValueRepository<LearnerProgress>
    implements ProgressRepository {
  ProgressRepositoryImpl(super.store)
    : super(storageKey: keyFor(LearnerProfile.legacyId));

  static String keyFor(String learnerId) => learnerId == LearnerProfile.legacyId
      ? 'wonderly.progress.v1'
      : 'wonderly.progress.v2.$learnerId';

  @override
  LearnerProgress get defaultValue => const LearnerProgress();

  @override
  LearnerProgress decode(Map<String, Object?> json) =>
      LearnerProgress.fromJson(json);

  @override
  Map<String, Object?> encode(LearnerProgress value) => value.toJson();

  @override
  Future<void> bindTo(String learnerId) async {
    await rebind(keyFor(learnerId));
  }

  @override
  Future<void> deleteFor(String learnerId) => deleteKey(keyFor(learnerId));
}
