import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/usecases/validate_profile.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';

class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.buddy = Buddy.cat,
    this.name = '',
    this.grade = 3,
    this.errorMessage,
    this.submitting = false,
    this.completed = false,
  });

  final Buddy buddy;
  final String name;
  final int grade;
  final String? errorMessage;
  final bool submitting;
  final bool completed;

  ProfileSetupState copyWith({
    Buddy? buddy,
    String? name,
    int? grade,
    String? Function()? errorMessage,
    bool? submitting,
    bool? completed,
  }) {
    return ProfileSetupState(
      buddy: buddy ?? this.buddy,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      submitting: submitting ?? this.submitting,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    buddy,
    name,
    grade,
    errorMessage,
    submitting,
    completed,
  ];
}

/// Form logic for creating or editing the learner profile.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(
    this._profileCubit, {
    ValidateProfile validate = const ValidateProfile(),
    LearnerProfile? initial,
    String Function()? newId,
  }) : _validate = validate,
       _id = initial?.id ?? (newId ?? const Uuid().v4)(),
       super(
         initial == null
             ? const ProfileSetupState()
             : ProfileSetupState(
                 buddy: initial.buddy,
                 name: initial.name,
                 grade: initial.grade,
               ),
       );

  final ProfileCubit _profileCubit;
  final ValidateProfile _validate;

  /// Id of the learner being created or edited.
  final String _id;

  void selectBuddy(Buddy buddy) => emit(state.copyWith(buddy: buddy));

  void changeName(String name) => emit(
    state.copyWith(
      name: name.length > AppConstants.maxNameLength
          ? name.substring(0, AppConstants.maxNameLength)
          : name,
      errorMessage: () => null,
    ),
  );

  void selectGrade(int grade) => emit(state.copyWith(grade: grade));

  Future<void> submit() async {
    if (state.submitting) return;
    final result = _validate(
      name: state.name,
      grade: state.grade,
      buddy: state.buddy,
      id: _id,
    );
    final profile = result.valueOrNull;
    if (profile == null) {
      emit(state.copyWith(errorMessage: () => result.failureOrNull?.message));
      return;
    }
    emit(state.copyWith(submitting: true, errorMessage: () => null));
    final saved = await _profileCubit.save(profile);
    emit(
      saved
          ? state.copyWith(submitting: false, completed: true)
          : state.copyWith(
              submitting: false,
              errorMessage: () => 'We could not save that. Please try again.',
            ),
    );
  }
}
