import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/usecases/validate_profile.dart';

void main() {
  const validate = ValidateProfile();

  test('accepts a valid profile and trims the name', () {
    final result = validate(name: '  Alex  ', grade: 3, buddy: Buddy.fox);
    expect(
      result.valueOrNull,
      const LearnerProfile(name: 'Alex', grade: 3, buddy: Buddy.fox),
    );
  });

  test('collapses repeated spaces inside the name', () {
    final result = validate(name: 'Mary   Ann', grade: 1, buddy: Buddy.cat);
    expect(result.valueOrNull?.name, 'Mary Ann');
  });

  test('rejects an empty or blank name', () {
    for (final name in ['', '   ']) {
      final result = validate(name: name, grade: 2, buddy: Buddy.cat);
      expect(result.failureOrNull, isA<ValidationFailure>());
    }
  });

  test('rejects names longer than the limit', () {
    final result = validate(name: 'A' * 21, grade: 2, buddy: Buddy.cat);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(
      validate(name: 'A' * 20, grade: 2, buddy: Buddy.cat).valueOrNull,
      isNotNull,
    );
  });

  test('rejects grades outside 1 to 5', () {
    for (final grade in [0, 6, -1]) {
      final result = validate(name: 'Alex', grade: grade, buddy: Buddy.cat);
      expect(result.failureOrNull, isA<ValidationFailure>());
    }
  });

  test('profile survives a JSON round trip and tolerates unknown buddies', () {
    const profile = LearnerProfile(name: 'Sam', grade: 4, buddy: Buddy.owl);
    expect(LearnerProfile.fromJson(profile.toJson()), profile);
    expect(
      LearnerProfile.fromJson({'name': 'Sam', 'grade': 4, 'buddy': 'dragon'})
          .buddy,
      Buddy.cat,
    );
  });
}
