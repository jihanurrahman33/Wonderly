import 'dart:convert';

import 'package:wonderly/core/storage/json_value_repository.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';

/// Stores the roster as one JSON document.
///
/// Data written by earlier versions (a single profile under the v1 key) is
/// migrated into a one-learner roster the first time it is read.
class ProfileRepositoryImpl extends JsonValueRepository<LearnerRoster>
    implements ProfileRepository {
  ProfileRepositoryImpl(super.store) : super(storageKey: 'wonderly.roster.v1');

  static const legacyProfileKey = 'wonderly.profile.v1';

  @override
  LearnerRoster get defaultValue {
    final raw = store.read(legacyProfileKey);
    if (raw == null) return const LearnerRoster();
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, Object?> && json.isNotEmpty) {
        final learner = LearnerProfile.fromJson(json);
        return LearnerRoster(learners: [learner], activeId: learner.id);
      }
    } on FormatException {
      // Unreadable legacy data: start fresh.
    }
    return const LearnerRoster();
  }

  @override
  LearnerRoster decode(Map<String, Object?> json) =>
      LearnerRoster.fromJson(json);

  @override
  Map<String, Object?> encode(LearnerRoster value) => value.toJson();
}
