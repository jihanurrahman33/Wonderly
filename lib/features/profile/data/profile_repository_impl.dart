import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/storage/json_value_repository.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';

/// Stores the profile as a single JSON document. An empty document means
/// "no profile yet".
class ProfileRepositoryImpl extends JsonValueRepository<LearnerProfile?>
    implements ProfileRepository {
  ProfileRepositoryImpl(super.store) : super(storageKey: 'wonderly.profile.v1');

  @override
  LearnerProfile? get defaultValue => null;

  @override
  LearnerProfile? decode(Map<String, Object?> json) =>
      json.isEmpty ? null : LearnerProfile.fromJson(json);

  @override
  Map<String, Object?> encode(LearnerProfile? value) =>
      value?.toJson() ?? const {};

  @override
  Future<Result<LearnerProfile>> save(LearnerProfile profile) async {
    final result = await update((_) => profile);
    return result.fold(
      onSuccess: (value) => Result.success(value ?? profile),
      onFailure: Result.failure,
    );
  }
}
