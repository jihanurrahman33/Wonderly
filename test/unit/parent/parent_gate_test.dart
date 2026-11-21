import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/parent/domain/parent_gate_challenge.dart';
import 'package:wonderly/features/parent/presentation/cubit/parent_gate_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeClock clock;
  late ParentGateCubit cubit;

  void enter(int value) {
    for (final digit in '$value'.split('')) {
      cubit.enterDigit(int.parse(digit));
    }
  }

  setUp(() {
    clock = FakeClock(DateTime(2026, 11, 21, 10));
    cubit = ParentGateCubit(clock: clock, random: Random(1));
  });

  tearDown(() => cubit.close());

  group('ParentGateChallenge', () {
    test('multiplies the two factors', () {
      const c = ParentGateChallenge(left: 7, right: 8);
      expect(c.answer, 56);
      expect(c.question, '7 × 8 =');
      expect(c.isCorrect('56'), isTrue);
      expect(c.isCorrect('57'), isFalse);
      expect(c.isCorrect('abc'), isFalse);
      expect(c.isCorrect(''), isFalse);
    });

    test('random factors stay between 6 and 9', () {
      final random = Random(7);
      for (var i = 0; i < 200; i++) {
        final c = ParentGateChallenge.random(random);
        expect(c.left, inInclusiveRange(6, 9));
        expect(c.right, inInclusiveRange(6, 9));
      }
    });
  });

  group('ParentGateCubit', () {
    test('verifies the correct answer', () {
      enter(cubit.state.challenge.answer);
      cubit.confirm();
      expect(cubit.state.verified, isTrue);
    });

    test('limits input to two digits and supports delete', () {
      cubit
        ..enterDigit(1)
        ..enterDigit(2)
        ..enterDigit(3);
      expect(cubit.state.input, '12');
      cubit.deleteDigit();
      expect(cubit.state.input, '1');
    });

    test('ignores confirm with no input', () {
      cubit.confirm();
      expect(cubit.state.verified, isFalse);
      expect(cubit.state.failedAttempts, 0);
    });

    test('a wrong answer clears input and shows a new question', () {
      final before = cubit.state.challenge;
      enter(before.answer + 1);
      cubit.confirm();
      expect(cubit.state.verified, isFalse);
      expect(cubit.state.wrongAnswer, isTrue);
      expect(cubit.state.input, isEmpty);
      expect(cubit.state.failedAttempts, 1);
    });

    test('locks after too many wrong answers, then unlocks', () {
      for (var i = 0; i < AppConstants.parentGateMaxAttempts; i++) {
        enter(cubit.state.challenge.answer + 1);
        cubit.confirm();
      }
      expect(cubit.state.isLocked(clock.now()), isTrue);

      // Input and confirm are ignored while locked, even with the right answer.
      enter(cubit.state.challenge.answer);
      cubit.confirm();
      expect(cubit.state.verified, isFalse);

      clock.current = clock.current.add(AppConstants.parentGateLockout);
      expect(cubit.state.isLocked(clock.now()), isFalse);
      enter(cubit.state.challenge.answer);
      cubit.confirm();
      expect(cubit.state.verified, isTrue);
    });

    test('rejects out of range digits', () {
      cubit
        ..enterDigit(10)
        ..enterDigit(-1);
      expect(cubit.state.input, isEmpty);
    });
  });

  group('ParentAccess', () {
    test('is active for five minutes after being granted', () {
      final access = ParentAccess(clock);
      expect(access.isActive, isFalse);
      access.grant();
      expect(access.isActive, isTrue);
      clock.current = clock.current.add(
        const Duration(minutes: 4, seconds: 59),
      );
      expect(access.isActive, isTrue);
      clock.current = clock.current.add(const Duration(seconds: 2));
      expect(access.isActive, isFalse);
    });

    test('can be revoked immediately', () {
      final access = ParentAccess(clock)..grant();
      access.revoke();
      expect(access.isActive, isFalse);
    });
  });
}
