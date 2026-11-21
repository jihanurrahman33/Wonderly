import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';

enum ProfileStatus { loading, ready, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.roster = const LearnerRoster(),
  });

  final ProfileStatus status;
  final LearnerRoster roster;

  /// The learner who is playing, or `null` before profile setup.
  LearnerProfile? get profile => roster.active;

  List<LearnerProfile> get learners => roster.learners;

  bool get hasProfile => profile != null;

  @override
  List<Object?> get props => [status, roster];
}

/// Holds the learners on this device and who is active.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, {Future<void> Function(String id)? onRemoved})
    : _onRemoved = onRemoved,
      super(const ProfileState());

  final ProfileRepository _repository;
  final Future<void> Function(String id)? _onRemoved;

  Future<void> load() async {
    final result = await _repository.load();
    emit(
      result.fold(
        onSuccess: (r) => ProfileState(status: ProfileStatus.ready, roster: r),
        onFailure: (_) => const ProfileState(status: ProfileStatus.failure),
      ),
    );
  }

  /// Adds or updates [profile] and makes it the active learner.
  /// Returns `false` if it could not be stored.
  Future<bool> save(LearnerProfile profile) =>
      _apply((r) => r.upsertActive(profile));

  Future<bool> switchTo(String id) => _apply((r) => r.withActive(id));

  /// Removes a learner and erases their progress.
  Future<bool> remove(String id) async {
    final ok = await _apply((r) => r.without(id));
    if (ok) await _onRemoved?.call(id);
    return ok;
  }

  Future<bool> _apply(LearnerRoster Function(LearnerRoster) transform) async {
    final result = await _repository.update(transform);
    return result.fold(
      onSuccess: (r) {
        emit(ProfileState(status: ProfileStatus.ready, roster: r));
        return true;
      },
      onFailure: (_) => false,
    );
  }
}
