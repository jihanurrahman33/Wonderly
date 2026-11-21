import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/parent/domain/parent_gate_challenge.dart';

class ParentGateState extends Equatable {
  const ParentGateState({
    required this.challenge,
    this.input = '',
    this.failedAttempts = 0,
    this.lockedUntil,
    this.wrongAnswer = false,
    this.verified = false,
  });

  final ParentGateChallenge challenge;
  final String input;
  final int failedAttempts;
  final DateTime? lockedUntil;

  /// True right after a wrong answer, so the UI can shake and explain.
  final bool wrongAnswer;
  final bool verified;

  bool isLocked(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  ParentGateState copyWith({
    ParentGateChallenge? challenge,
    String? input,
    int? failedAttempts,
    DateTime? Function()? lockedUntil,
    bool? wrongAnswer,
    bool? verified,
  }) {
    return ParentGateState(
      challenge: challenge ?? this.challenge,
      input: input ?? this.input,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil != null ? lockedUntil() : this.lockedUntil,
      wrongAnswer: wrongAnswer ?? this.wrongAnswer,
      verified: verified ?? this.verified,
    );
  }

  @override
  List<Object?> get props => [
    challenge,
    input,
    failedAttempts,
    lockedUntil,
    wrongAnswer,
    verified,
  ];
}

/// Keeps children out of the grown-ups zone with a quick maths question.
class ParentGateCubit extends Cubit<ParentGateState> {
  ParentGateCubit({required Clock clock, Random? random})
    : _clock = clock,
      _random = random ?? Random(),
      super(
        ParentGateState(
          challenge: ParentGateChallenge.random(random ?? Random()),
        ),
      );

  static const _maxDigits = 2;

  final Clock _clock;
  final Random _random;

  void enterDigit(int digit) {
    if (digit < 0 || digit > 9) return;
    if (state.isLocked(_clock.now()) || state.verified) return;
    if (state.input.length >= _maxDigits) return;
    emit(state.copyWith(input: '${state.input}$digit', wrongAnswer: false));
  }

  void deleteDigit() {
    if (state.input.isEmpty) return;
    emit(
      state.copyWith(
        input: state.input.substring(0, state.input.length - 1),
        wrongAnswer: false,
      ),
    );
  }

  void confirm() {
    final now = _clock.now();
    if (state.isLocked(now) || state.verified || state.input.isEmpty) return;
    if (state.challenge.isCorrect(state.input)) {
      emit(state.copyWith(verified: true, wrongAnswer: false));
      return;
    }
    final failures = state.failedAttempts + 1;
    final lock = failures >= AppConstants.parentGateMaxAttempts;
    emit(
      state.copyWith(
        challenge: ParentGateChallenge.random(_random),
        input: '',
        failedAttempts: lock ? 0 : failures,
        lockedUntil: () =>
            lock ? now.add(AppConstants.parentGateLockout) : null,
        wrongAnswer: true,
      ),
    );
  }
}
