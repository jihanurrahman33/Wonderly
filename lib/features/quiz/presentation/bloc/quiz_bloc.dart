import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';
import 'package:wonderly/features/progress/domain/usecases/record_answer.dart';
import 'package:wonderly/features/progress/domain/usecases/record_play_time.dart';
import 'package:wonderly/features/quiz/domain/quiz_summary.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_event.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_state.dart';
import 'package:wonderly/features/settings/domain/repositories/settings_repository.dart';
import 'package:wonderly/features/settings/domain/services/play_guard.dart';

/// Runs one quiz session: question flow, answer checking, progress saving and
/// the parent-set play limit.
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc({
    required CatalogRepository catalog,
    required ProgressRepository progress,
    required SettingsRepository settings,
    required RecordAnswer recordAnswer,
    required RecordPlayTime recordPlayTime,
    required Clock clock,
    Stream<void> Function()? tickerFactory,
  }) : _catalog = catalog,
       _progress = progress,
       _settings = settings,
       _recordAnswer = recordAnswer,
       _recordPlayTime = recordPlayTime,
       _clock = clock,
       _tickerFactory =
           tickerFactory ??
           (() => Stream<void>.periodic(AppConstants.playTickInterval)),
       super(const QuizState()) {
    on<QuizStarted>(_onStarted);
    on<QuizOptionSelected>(_onOptionSelected);
    on<QuizShapePlaced>(_onShapePlaced);
    // Dropping repeat taps stops a double-tap counting one answer twice.
    on<QuizNextPressed>(_onNext, transformer: droppable());
    on<QuizHintToggled>(
      (event, emit) => emit(state.copyWith(hintVisible: !state.hintVisible)),
    );
    on<QuizTicked>(_onTicked, transformer: sequential());
    on<QuizLifecycleChanged>(
      (event, emit) => emit(state.copyWith(paused: !event.active)),
    );
  }

  static const _flushEveryTicks = 5;

  final CatalogRepository _catalog;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final RecordAnswer _recordAnswer;
  final RecordPlayTime _recordPlayTime;
  final Clock _clock;
  final Stream<void> Function() _tickerFactory;

  StreamSubscription<void>? _ticker;
  int _pendingSeconds = 0;

  Future<void> _onStarted(QuizStarted event, Emitter<QuizState> emit) async {
    final loaded = await _catalog.load();
    final set = loaded.valueOrNull?.setById(event.setId);
    if (set == null || set.isEmpty) {
      emit(state.copyWith(status: QuizStatus.failed));
      return;
    }
    final progress = (await _progress.load()).valueOrNull;
    if (progress != null && set.isLocked(progress.stars)) {
      emit(state.copyWith(status: QuizStatus.failed));
      return;
    }
    final blocked = await _checkAllowance();
    final start = (progress?.setCursor[set.id] ?? 0).clamp(0, set.length - 1);
    if (blocked != null) {
      emit(
        state.copyWith(
          status: QuizStatus.blocked,
          set: set,
          blockReason: blocked.reason,
        ),
      );
      return;
    }
    emit(state.copyWith(status: QuizStatus.playing, set: set, index: start));
    _startTicker();
  }

  void _onOptionSelected(QuizOptionSelected event, Emitter<QuizState> emit) {
    if (state.status != QuizStatus.playing || state.revealed) return;
    final q = state.question;
    final count = switch (q) {
      ChoiceQuestion(:final options) => options.length,
      PatternQuestion(:final options) => options.length,
      _ => 0,
    };
    if (event.index < 0 || event.index >= count) return;
    emit(state.copyWith(selected: () => event.index));
  }

  void _onShapePlaced(QuizShapePlaced event, Emitter<QuizState> emit) {
    final q = state.question;
    if (state.status != QuizStatus.playing || q is! ShapeMatchQuestion) return;
    if (!q.shapes.contains(event.shape)) return;
    emit(state.copyWith(placed: {...state.placed, event.shape}));
  }

  Future<void> _onNext(QuizNextPressed event, Emitter<QuizState> emit) async {
    final q = state.question;
    if (state.status != QuizStatus.playing || q == null) return;
    if (state.revealed) {
      _advance(emit);
      return;
    }
    if (!state.canAdvance) return;

    final (correct, record) = _evaluate(q);
    final result = await _recordAnswer(
      question: q,
      setLength: state.total,
      correct: correct,
    );
    final outcome = result.valueOrNull;
    final answers = [...state.answers, record];
    final next = state.copyWith(
      revealed: true,
      lastCorrect: () => correct,
      correctCount: state.correctCount + (correct ? 1 : 0),
      answers: answers,
      starsEarned: state.starsEarned + (outcome?.starsGained ?? 0),
      lastStars: outcome?.starsGained ?? 0,
      newBadges: [...state.newBadges, ...?outcome?.newBadges],
      saveFailed: result.failureOrNull != null,
    );
    // Drag-and-match shows no feedback panel: move straight on.
    if (q is ShapeMatchQuestion) {
      emit(next);
      _advance(emit);
      return;
    }
    emit(next);
  }

  (bool, AnswerRecord) _evaluate(Question q) {
    switch (q) {
      case ChoiceQuestion():
        final picked = state.selected ?? -1;
        return (
          q.isCorrect(picked),
          AnswerRecord(
            question: q,
            correct: q.isCorrect(picked),
            chosenLabel: picked >= 0 ? q.options[picked].label : null,
            correctLabel: q.options[q.answerIndex].label,
          ),
        );
      case PatternQuestion():
        final picked = state.selected ?? -1;
        return (
          q.isCorrect(picked),
          AnswerRecord(
            question: q,
            correct: q.isCorrect(picked),
            chosenLabel: picked >= 0 ? q.options[picked] : null,
            correctLabel: q.options[q.answerIndex],
          ),
        );
      case ShapeMatchQuestion():
        return (
          true,
          AnswerRecord(question: q, correct: true, correctLabel: 'All matched'),
        );
    }
  }

  void _advance(Emitter<QuizState> emit) {
    final last = state.index + 1 >= state.total;
    if (!last) {
      emit(
        state.copyWith(
          index: state.index + 1,
          selected: () => null,
          revealed: false,
          lastCorrect: () => null,
          placed: const {},
          hintVisible: false,
        ),
      );
      return;
    }
    unawaited(_stopTicker());
    final set = state.set;
    if (set == null) return;
    emit(
      state.copyWith(
        status: QuizStatus.finished,
        summary: QuizSummary(
          setId: set.id,
          setTitle: set.title,
          correct: state.correctCount,
          total: state.answers.length,
          seconds: state.seconds,
          stars: state.starsEarned,
          newBadges: List.unmodifiable(state.newBadges),
          answers: List.unmodifiable(state.answers),
        ),
      ),
    );
  }

  Future<void> _onTicked(QuizTicked event, Emitter<QuizState> emit) async {
    if (state.status != QuizStatus.playing || state.paused) return;
    _pendingSeconds++;
    emit(state.copyWith(seconds: state.seconds + 1));
    if (_pendingSeconds < _flushEveryTicks) return;
    await _flushPlayTime();
    final blocked = await _checkAllowance();
    if (blocked != null && state.status == QuizStatus.playing) {
      await _stopTicker();
      emit(
        state.copyWith(status: QuizStatus.blocked, blockReason: blocked.reason),
      );
    }
  }

  Future<PlayBlocked?> _checkAllowance() async {
    final progress = (await _progress.load()).valueOrNull;
    final settings = (await _settings.load()).valueOrNull;
    if (progress == null || settings == null) return null;
    final now = _clock.now();
    final allowance = PlayGuard.check(
      now: now,
      secondsPlayedToday: progress.dailySeconds[DayKey.of(now)] ?? 0,
      dailyLimitMinutes: settings.dailyLimitMinutes,
      bedtimeMode: settings.bedtimeMode,
    );
    return allowance is PlayBlocked ? allowance : null;
  }

  Future<void> _flushPlayTime() async {
    final seconds = _pendingSeconds;
    if (seconds == 0) return;
    _pendingSeconds = 0;
    await _recordPlayTime(seconds);
  }

  void _startTicker() {
    _ticker ??= _tickerFactory().listen((_) => add(const QuizTicked()));
  }

  Future<void> _stopTicker() async {
    await _ticker?.cancel();
    _ticker = null;
    await _flushPlayTime();
  }

  @override
  Future<void> close() async {
    await _stopTicker();
    return super.close();
  }
}
