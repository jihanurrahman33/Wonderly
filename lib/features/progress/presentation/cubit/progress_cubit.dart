import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';
import 'package:wonderly/features/progress/domain/services/streak_calculator.dart';

class ProgressState extends Equatable {
  const ProgressState({
    this.progress = const LearnerProgress(),
    this.streak = 0,
    this.playedToday = false,
    this.loaded = false,
  });

  final LearnerProgress progress;
  final int streak;
  final bool playedToday;
  final bool loaded;

  @override
  List<Object?> get props => [progress, streak, playedToday, loaded];
}

/// Mirrors stored progress and derives the current streak.
class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._repository, this._clock) : super(const ProgressState());

  final ProgressRepository _repository;
  final Clock _clock;
  StreamSubscription<LearnerProgress>? _subscription;

  Future<void> load() async {
    final result = await _repository.load();
    _emitProgress(result.valueOrNull ?? const LearnerProgress());
    await _subscription?.cancel();
    _subscription = _repository.watch().listen(_emitProgress);
  }

  /// Recomputes day-dependent values, for example after the app resumes.
  void refresh() => _emitProgress(state.progress);

  void _emitProgress(LearnerProgress progress) {
    final now = _clock.now();
    emit(
      ProgressState(
        progress: progress,
        streak: StreakCalculator.current(progress.activeDays, now),
        playedToday: StreakCalculator.playedToday(progress.activeDays, now),
        loaded: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
