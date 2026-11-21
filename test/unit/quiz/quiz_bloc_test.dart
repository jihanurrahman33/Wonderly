import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';
import 'package:wonderly/features/progress/data/progress_repository_impl.dart';
import 'package:wonderly/features/progress/domain/usecases/record_answer.dart';
import 'package:wonderly/features/progress/domain/usecases/record_play_time.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_event.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_state.dart';
import 'package:wonderly/features/settings/data/settings_repository_impl.dart';
import 'package:wonderly/features/settings/domain/services/play_guard.dart';

import '../../helpers/fakes.dart';

class _FakeCatalog implements CatalogRepository {
  _FakeCatalog(this.catalog);

  final Catalog catalog;

  @override
  Future<Result<Catalog>> load() async => Result.success(catalog);
}

void main() {
  late InMemoryStore store;
  late ProgressRepositoryImpl progress;
  late SettingsRepositoryImpl settings;
  late FakeClock clock;
  late StreamController<void> ticker;

  QuizBloc build(Catalog catalog) {
    return QuizBloc(
      catalog: _FakeCatalog(catalog),
      progress: progress,
      settings: settings,
      recordAnswer: RecordAnswer(progress, clock),
      recordPlayTime: RecordPlayTime(progress, clock),
      clock: clock,
      tickerFactory: () => ticker.stream,
    );
  }

  setUp(() {
    store = InMemoryStore();
    progress = ProgressRepositoryImpl(store);
    settings = SettingsRepositoryImpl(store);
    clock = FakeClock(DateTime(2026, 11, 21, 10));
    ticker = StreamController<void>.broadcast();
  });

  tearDown(() => ticker.close());

  Future<QuizBloc> started(Catalog catalog, String setId) async {
    final bloc = build(catalog);
    bloc.add(QuizStarted(setId));
    await bloc.stream.firstWhere((s) => s.status != QuizStatus.loading);
    return bloc;
  }

  Future<void> settle() => pumpEventQueue();

  /// Sends [events] one at a time, letting each finish before the next.
  Future<void> send(QuizBloc bloc, List<QuizEvent> events) async {
    for (final e in events) {
      bloc.add(e);
      await settle();
    }
  }

  group('starting', () {
    test('opens at the first question of an unstarted set', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      expect(bloc.state.status, QuizStatus.playing);
      expect(bloc.state.index, 0);
      expect(bloc.state.total, 3);
      await bloc.close();
    });

    test('resumes where the child left off', () async {
      await progress.update((p) => p.copyWith(setCursor: {'a': 2}));
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      expect(bloc.state.index, 2);
      await bloc.close();
    });

    test('fails for an unknown set', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'missing');
      expect(bloc.state.status, QuizStatus.failed);
      await bloc.close();
    });

    test('fails for a set that is still locked', () async {
      final catalog = Catalog([quizSet('a', unlockStars: 30)]);
      final bloc = await started(catalog, 'a');
      expect(bloc.state.status, QuizStatus.failed);
      await bloc.close();
    });

    test('is blocked when the daily limit is already used up', () async {
      await progress.update(
        (p) => p.copyWith(dailySeconds: {'2026-11-21': 30 * 60}),
      );
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      expect(bloc.state.status, QuizStatus.blocked);
      expect(bloc.state.blockReason, BreakReason.dailyLimit);
      await bloc.close();
    });

    test('is blocked at bedtime when bedtime mode is on', () async {
      await settings.update((s) => s.copyWith(bedtimeMode: true));
      clock.current = DateTime(2026, 11, 21, 20);
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      expect(bloc.state.blockReason, BreakReason.bedtime);
      await bloc.close();
    });
  });

  group('answering', () {
    test('Next is disabled until an option is chosen', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      expect(bloc.state.canAdvance, isFalse);
      bloc.add(const QuizNextPressed());
      await settle();
      expect(bloc.state.revealed, isFalse);
      bloc.add(const QuizOptionSelected(1));
      await settle();
      expect(bloc.state.canAdvance, isTrue);
      await bloc.close();
    });

    test('ignores out of range selections', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      await send(bloc, [
        const QuizOptionSelected(9),
        const QuizOptionSelected(-1),
      ]);

      await settle();
      expect(bloc.state.selected, isNull);
      await bloc.close();
    });

    test('first Next reveals a correct answer and awards a star', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      await send(bloc, [const QuizOptionSelected(1), const QuizNextPressed()]);

      await settle();
      await settle();
      expect(bloc.state.revealed, isTrue);
      expect(bloc.state.lastCorrect, isTrue);
      expect(bloc.state.lastStars, 1);
      expect(bloc.state.index, 0);
      expect((await progress.load()).valueOrNull?.stars, 1);
      await bloc.close();
    });

    test('a wrong answer is revealed without stars', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      await send(bloc, [const QuizOptionSelected(0), const QuizNextPressed()]);

      await settle();
      await settle();
      expect(bloc.state.lastCorrect, isFalse);
      expect(bloc.state.starsEarned, 0);
      await bloc.close();
    });

    test('selection is locked once the answer is revealed', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      await send(bloc, [const QuizOptionSelected(1), const QuizNextPressed()]);

      await settle();
      await settle();
      bloc.add(const QuizOptionSelected(0));
      await settle();
      expect(bloc.state.selected, 1);
      await bloc.close();
    });

    test('second Next moves to the next question', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      await send(bloc, [
        const QuizOptionSelected(1),
        const QuizNextPressed(),
        const QuizNextPressed(),
      ]);

      await settle();
      await settle();
      expect(bloc.state.index, 1);
      expect(bloc.state.revealed, isFalse);
      expect(bloc.state.selected, isNull);
      await bloc.close();
    });

    test('persists the cursor after every answer', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      await send(bloc, [const QuizOptionSelected(1), const QuizNextPressed()]);

      await settle();
      await settle();
      expect((await progress.load()).valueOrNull?.setCursor['a'], 1);
      await bloc.close();
    });
  });

  group('finishing', () {
    test('summarises the session after the last question', () async {
      final bloc = await started(Catalog([quizSet('a', questions: 2)]), 'a');
      // Q1 correct, Q2 wrong.
      await send(bloc, [
        const QuizOptionSelected(1),
        const QuizNextPressed(),
        const QuizNextPressed(),
        const QuizOptionSelected(0),
        const QuizNextPressed(),
        const QuizNextPressed(),
      ]);

      expect(bloc.state.status, QuizStatus.finished);

      final summary = bloc.state.summary!;
      expect(summary.setId, 'a');
      expect(summary.correct, 1);
      expect(summary.total, 2);
      expect(summary.answers.map((a) => a.correct), [true, false]);
      expect(summary.answers.last.chosenLabel, 'A');
      expect(summary.answers.last.correctLabel, 'B');
      // 1 star + 4 completion bonus + 5 for the Zoology Explorer badge.
      expect(summary.stars, 10);
      final saved = (await progress.load()).valueOrNull!;
      expect(saved.completedSetIds, {'a'});
      expect(saved.setCursor, isEmpty);
      await bloc.close();
    });

    test('a completed zoology set unlocks Zoology Explorer', () async {
      final bloc = await started(Catalog([quizSet('a', questions: 1)]), 'a');
      await send(bloc, [
        const QuizOptionSelected(1),
        const QuizNextPressed(),
        const QuizNextPressed(),
      ]);

      expect(bloc.state.status, QuizStatus.finished);
      expect(bloc.state.summary?.newBadges, hasLength(1));
      await bloc.close();
    });
  });

  group('shape matching', () {
    Catalog matchCatalog() => const Catalog([
      QuizSet(
        id: 'g',
        subject: Subject.geometry,
        title: 'Shapes',
        questions: [
          ShapeMatchQuestion(
            id: 'g1',
            subject: Subject.geometry,
            setId: 'g',
            prompt: 'Match',
            shapes: ['circle', 'square'],
          ),
        ],
      ),
    ]);

    test('Next stays disabled until every shape is placed', () async {
      final bloc = await started(matchCatalog(), 'g');
      bloc.add(const QuizShapePlaced('circle'));
      await settle();
      expect(bloc.state.canAdvance, isFalse);
      bloc.add(const QuizShapePlaced('square'));
      await settle();
      expect(bloc.state.canAdvance, isTrue);
      await bloc.close();
    });

    test('ignores shapes that are not part of the question', () async {
      final bloc = await started(matchCatalog(), 'g');
      bloc.add(const QuizShapePlaced('star'));
      await settle();
      expect(bloc.state.placed, isEmpty);
      await bloc.close();
    });

    test('finishing the only question completes the set', () async {
      final bloc = await started(matchCatalog(), 'g');
      await send(bloc, [
        const QuizShapePlaced('circle'),
        const QuizShapePlaced('square'),
        const QuizNextPressed(),
      ]);

      expect(bloc.state.status, QuizStatus.finished);
      expect(bloc.state.summary?.correct, 1);
      await bloc.close();
    });
  });

  group('play time', () {
    test('counts seconds and flushes them to storage', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      for (var i = 0; i < 5; i++) {
        ticker.add(null);
        await settle();
      }
      await settle();
      expect(bloc.state.seconds, 5);
      expect(
        (await progress.load()).valueOrNull?.dailySeconds['2026-11-21'],
        5,
      );
      await bloc.close();
    });

    test('does not count time while the app is in the background', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      bloc.add(const QuizLifecycleChanged(active: false));
      await settle();
      ticker.add(null);
      await settle();
      expect(bloc.state.seconds, 0);

      bloc.add(const QuizLifecycleChanged(active: true));
      await settle();
      ticker.add(null);
      await settle();
      expect(bloc.state.seconds, 1);
      await bloc.close();
    });

    test('ends the session when the daily limit is reached mid quiz', () async {
      await settings.update((s) => s.copyWith(dailyLimitMinutes: 10));
      await progress.update(
        (p) => p.copyWith(dailySeconds: {'2026-11-21': 10 * 60 - 3}),
      );
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      expect(bloc.state.status, QuizStatus.playing);

      for (var i = 0; i < 5; i++) {
        ticker.add(null);
        await settle();
      }
      await settle();
      expect(bloc.state.status, QuizStatus.blocked);
      expect(bloc.state.blockReason, BreakReason.dailyLimit);
      await bloc.close();
    });

    test('flushes pending seconds when the bloc is closed', () async {
      final bloc = await started(Catalog([quizSet('a')]), 'a');
      ticker.add(null);
      await settle();
      await bloc.close();
      expect(
        (await progress.load()).valueOrNull?.dailySeconds['2026-11-21'],
        1,
      );
    });
  });

  blocTest<QuizBloc, QuizState>(
    'toggles the hint',
    build: () => build(Catalog([quizSet('a')])),
    act: (b) => b
      ..add(const QuizHintToggled())
      ..add(const QuizHintToggled()),
    expect: () => [
      isA<QuizState>().having((s) => s.hintVisible, 'hintVisible', isTrue),
      isA<QuizState>().having((s) => s.hintVisible, 'hintVisible', isFalse),
    ],
  );
}
