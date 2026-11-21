import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/services/badge_rules.dart';
import 'package:wonderly/features/progress/domain/services/progress_reducer.dart';
import 'package:wonderly/features/progress/domain/services/streak_calculator.dart';

LearnerProgress answer(
  LearnerProgress p, {
  required String id,
  bool correct = true,
  String setId = 'set',
  int length = 3,
  Subject subject = Subject.plants,
  DateTime? now,
}) {
  return ProgressReducer.applyAnswer(
    p,
    questionId: id,
    setId: setId,
    subject: subject,
    setLength: length,
    correct: correct,
    now: now ?? DateTime(2026, 11, 21, 10),
  ).$1;
}

void main() {
  final today = DateTime(2026, 11, 21, 10);

  group('StreakCalculator', () {
    test('is zero with no active days', () {
      expect(StreakCalculator.current({}, today), 0);
    });

    test('counts consecutive days ending today', () {
      final days = {'2026-11-21', '2026-11-20', '2026-11-19'};
      expect(StreakCalculator.current(days, today), 3);
    });

    test('keeps the streak alive when only yesterday was played', () {
      final days = {'2026-11-20', '2026-11-19'};
      expect(StreakCalculator.current(days, today), 2);
    });

    test('resets after a missed day', () {
      final days = {'2026-11-19', '2026-11-18'};
      expect(StreakCalculator.current(days, today), 0);
    });

    test('counts only the run touching today, not older runs', () {
      final days = {'2026-11-21', '2026-11-20', '2026-11-10', '2026-11-09'};
      expect(StreakCalculator.current(days, today), 2);
    });

    test('reports whether today was played', () {
      expect(StreakCalculator.playedToday({'2026-11-21'}, today), isTrue);
      expect(StreakCalculator.playedToday({'2026-11-20'}, today), isFalse);
    });
  });

  group('ProgressReducer.applyAnswer', () {
    test('awards a star for a first correct answer', () {
      final (p, outcome) = ProgressReducer.applyAnswer(
        const LearnerProgress(),
        questionId: 'q1',
        setId: 'set',
        subject: Subject.plants,
        setLength: 3,
        correct: true,
        now: today,
      );
      expect(outcome.starsGained, AppConstants.starsPerCorrectAnswer);
      expect(p.stars, 1);
      expect(p.setCursor['set'], 1);
      expect(p.correctQuestionIds, {'q1'});
      expect(p.dailyStars['2026-11-21'], 1);
      expect(p.activeDays, {'2026-11-21'});
    });

    test('awards nothing for a wrong answer but still advances', () {
      final p = answer(const LearnerProgress(), id: 'q1', correct: false);
      expect(p.stars, 0);
      expect(p.setCursor['set'], 1);
      expect(p.currentRun, 0);
    });

    test('does not award stars twice for the same question', () {
      var p = answer(const LearnerProgress(), id: 'q1', length: 5);
      p = answer(p, id: 'q1', length: 5);
      expect(p.stars, 1);
    });

    test('adds a completion bonus once and clears the cursor', () {
      var p = const LearnerProgress();
      for (final id in ['a', 'b', 'c']) {
        p = answer(p, id: id);
      }
      expect(p.completedSetIds, {'set'});
      expect(p.setCursor, isEmpty);
      expect(p.completedSubjects, {Subject.plants});
      expect(p.stars, 3 + AppConstants.starsForFirstCompletion);

      // Replaying the set pays no second completion bonus.
      // (A wrong answer in between avoids tripping the Quick Thinker badge.)
      var replay = p;
      replay = answer(replay, id: 'a');
      replay = answer(replay, id: 'b', correct: false);
      replay = answer(replay, id: 'c');
      expect(replay.stars, p.stars);
    });

    test('tracks the best run of correct answers', () {
      var p = const LearnerProgress();
      p = answer(p, id: '1', length: 20);
      p = answer(p, id: '2', length: 20);
      p = answer(p, id: '3', correct: false, length: 20);
      p = answer(p, id: '4', length: 20);
      expect(p.bestRun, 2);
      expect(p.currentRun, 1);
    });

    test('unlocks Quick Thinker with five correct in a row', () {
      var p = const LearnerProgress();
      late AnswerOutcome outcome;
      for (var i = 1; i <= AppConstants.quickThinkerRun; i++) {
        final r = ProgressReducer.applyAnswer(
          p,
          questionId: 'q$i',
          setId: 'long',
          subject: Subject.logic,
          setLength: 20,
          correct: true,
          now: today,
        );
        p = r.$1;
        outcome = r.$2;
      }
      expect(p.badges, contains(BadgeId.quickThinker));
      expect(outcome.newBadges, [BadgeId.quickThinker]);
      expect(outcome.starsGained, 1 + AppConstants.starsPerBadge);
    });

    test('unlocks a subject badge when its set is completed', () {
      var p = const LearnerProgress();
      for (final id in ['a', 'b']) {
        p = answer(p, id: id, length: 2, subject: Subject.zoology);
      }
      expect(p.badges, contains(BadgeId.zoologyExplorer));
    });

    test('never unlocks the same badge twice', () {
      var p = const LearnerProgress();
      for (final id in ['a', 'b']) {
        p = answer(p, id: id, length: 2, subject: Subject.zoology);
      }
      final before = p.stars;
      for (final id in ['a', 'b']) {
        p = answer(p, id: id, length: 2, subject: Subject.zoology);
      }
      expect(p.badges.where((b) => b == BadgeId.zoologyExplorer), hasLength(1));
      expect(p.stars, before);
    });

    test('chains badges whose bonus stars unlock another badge', () {
      // 25 stars + 1 correct = 26; completion bonus 4 -> 30 => Plant Pal.
      const start = LearnerProgress(stars: 25, setCursor: {'set': 2});
      final (p, outcome) = ProgressReducer.applyAnswer(
        start,
        questionId: 'last',
        setId: 'set',
        subject: Subject.plants,
        setLength: 3,
        correct: true,
        now: today,
      );
      expect(outcome.completedSet, isTrue);
      expect(p.badges, contains(BadgeId.plantPal));
      expect(p.stars, 25 + 1 + 4 + AppConstants.starsPerBadge);
    });
  });

  group('ProgressReducer.applySeconds', () {
    test('adds seconds to today and ignores non-positive values', () {
      var p = ProgressReducer.applySeconds(const LearnerProgress(), 30, today);
      p = ProgressReducer.applySeconds(p, 15, today);
      expect(p.dailySeconds['2026-11-21'], 45);
      expect(ProgressReducer.applySeconds(p, 0, today), p);
      expect(ProgressReducer.applySeconds(p, -5, today), p);
    });
  });

  group('BadgeRules', () {
    test('Week Warrior needs a seven day streak', () {
      final days = {
        for (var i = 0; i < 7; i++) DayKey.of(DateTime(2026, 11, 21 - i)),
      };
      final p = LearnerProgress(activeDays: days);
      expect(BadgeRules.isEarned(BadgeId.weekWarrior, p, today), isTrue);
      final six = LearnerProgress(activeDays: {...days}..remove('2026-11-15'));
      expect(BadgeRules.isEarned(BadgeId.weekWarrior, six, today), isFalse);
    });

    test('plantPalFraction is clamped to 1', () {
      expect(BadgeRules.plantPalFraction(15), 0.5);
      expect(BadgeRules.plantPalFraction(500), 1);
    });
  });

  group('LearnerProgress', () {
    test('survives a JSON round trip', () {
      const p = LearnerProgress(
        stars: 12,
        setCursor: {'a': 2},
        completedSetIds: {'b'},
        completedSubjects: {Subject.logic},
        correctQuestionIds: {'q1', 'q2'},
        dailyStars: {'2026-11-21': 3},
        dailySeconds: {'2026-11-21': 90},
        activeDays: {'2026-11-21'},
        badges: {BadgeId.puzzlePro},
        bestStreak: 4,
        currentRun: 2,
        bestRun: 6,
      );
      expect(LearnerProgress.fromJson(p.toJson()), p);
    });

    test('ignores unknown badges and subjects in stored data', () {
      final p = LearnerProgress.fromJson({
        'badges': ['plantPal', 'not-a-badge'],
        'completedSubjects': ['logic', 'cooking'],
      });
      expect(p.badges, {BadgeId.plantPal});
      expect(p.completedSubjects, {Subject.logic});
    });

    test(
      'doneIn is the full length for completed sets and clamped otherwise',
      () {
        const p = LearnerProgress(
          completedSetIds: {'done'},
          setCursor: {'half': 99},
        );
        expect(p.doneIn('done', 10), 10);
        expect(p.doneIn('half', 10), 10);
        expect(p.doneIn('none', 10), 0);
      },
    );
  });
}
