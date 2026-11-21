import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';

enum ProfileStatus { loading, ready, failure }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.loading, this.profile});

  final ProfileStatus status;

  /// `null` until the child finishes profile setup.
  final LearnerProfile? profile;

  bool get hasProfile => profile != null;

  @override
  List<Object?> get props => [status, profile];
}

/// Holds the active learner profile for the whole app.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load() async {
    final result = await _repository.load();
    emit(
      result.fold(
        onSuccess: (p) => ProfileState(status: ProfileStatus.ready, profile: p),
        onFailure: (_) => const ProfileState(status: ProfileStatus.failure),
      ),
    );
  }

  /// Saves [profile]. Returns `false` if it could not be stored.
  Future<bool> save(LearnerProfile profile) async {
    final result = await _repository.save(profile);
    return result.fold(
      onSuccess: (saved) {
        emit(ProfileState(status: ProfileStatus.ready, profile: saved));
        return true;
      },
      onFailure: (_) => false,
    );
  }
}
