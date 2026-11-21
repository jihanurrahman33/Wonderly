import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';

/// Validates and normalises profile input at the system boundary.
class ValidateProfile {
  const ValidateProfile();

  Result<LearnerProfile> call({
    required String name,
    required int grade,
    required Buddy buddy,
  }) {
    final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      return const Result.failure(ValidationFailure('Please type your name.'));
    }
    if (trimmed.length > AppConstants.maxNameLength) {
      return const Result.failure(
        ValidationFailure(
          'Names can have up to ${AppConstants.maxNameLength} letters.',
        ),
      );
    }
    if (grade < AppConstants.minGrade || grade > AppConstants.maxGrade) {
      return const Result.failure(ValidationFailure('Please pick your grade.'));
    }
    return Result.success(
      LearnerProfile(name: trimmed, grade: grade, buddy: buddy),
    );
  }
}
