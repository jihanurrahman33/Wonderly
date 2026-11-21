import 'package:wonderly/core/storage/json_value_repository.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl extends JsonValueRepository<LearnerProgress>
    implements ProgressRepository {
  ProgressRepositoryImpl(super.store)
    : super(storageKey: 'wonderly.progress.v1');

  @override
  LearnerProgress get defaultValue => const LearnerProgress();

  @override
  LearnerProgress decode(Map<String, Object?> json) =>
      LearnerProgress.fromJson(json);

  @override
  Map<String, Object?> encode(LearnerProgress value) => value.toJson();
}
