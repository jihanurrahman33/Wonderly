import 'package:equatable/equatable.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/services/badge_rules.dart';
import 'package:wonderly/features/progress/domain/services/streak_calculator.dart';

/// What a single answer changed, for feedback in the UI.
class AnswerOutcome extends Equatable {
  const AnswerOutcome({
    required this.starsGained,
    required this.completedSet,
    required this.newBadges,
  });

  final int starsGained;
  final bool completedSet;
  final List<BadgeId> newBadges;

  @override
  List<Object?> get props => [starsGained, completedSet, newBadges];
}

/// Pure state transitions for [LearnerProgress].
abstract final class ProgressReducer {
  /// Applies one answered question and returns the new progress and outcome.
  static (LearnerProgress, AnswerOutcome) applyAnswer(
    LearnerProgress progress, {
    required String questionId,
    required String setId,
    required Subject subject,
    required int setLength,
    required bool correct,
    required DateTime now,
  }) {
    var stars = 0;
    final correctIds = {...progress.correctQuestionIds};
    if (correct && correctIds.add(questionId)) {
      stars += AppConstants.starsPerCorrectAnswer;
    }

    final run = correct ? progress.currentRun + 1 : 0;
    final bestRun = run > progress.bestRun ? run : progress.bestRun;

    final cursor = {...progress.setCursor};
    final completed = {...progress.completedSetIds};
    final completedSubjects = {...progress.completedSubjects};
    final nextIndex = (cursor[setId] ?? 0) + 1;
    var completedSet = false;
    if (nextIndex >= setLength) {
      cursor.remove(setId);
      completedSet = true;
      if (completed.add(setId)) stars += AppConstants.starsForFirstCompletion;
      completedSubjects.add(subject);
    } else {
      cursor[setId] = nextIndex;
    }

    final day = DayKey.of(now);
    final activeDays = {...progress.activeDays, day};
    var next = progress.copyWith(
      stars: progress.stars + stars,
      setCursor: cursor,
      completedSetIds: completed,
      completedSubjects: completedSubjects,
      correctQuestionIds: correctIds,
      dailyStars: _add(progress.dailyStars, day, stars),
      activeDays: activeDays,
      currentRun: run,
      bestRun: bestRun,
    );

    final streak = StreakCalculator.current(activeDays, now);
    if (streak > next.bestStreak) next = next.copyWith(bestStreak: streak);

    final unlocked = <BadgeId>[];
    // Bonus stars can themselves unlock another badge, so iterate to a fixed
    // point. Bounded by the number of badges.
    for (var i = 0; i < BadgeId.values.length; i++) {
      final fresh = BadgeRules.newlyEarned(next, now);
      if (fresh.isEmpty) break;
      final bonus = fresh.length * AppConstants.starsPerBadge;
      stars += bonus;
      unlocked.addAll(fresh);
      next = next.copyWith(
        badges: {...next.badges, ...fresh},
        stars: next.stars + bonus,
        dailyStars: _add(next.dailyStars, day, bonus),
      );
    }

    return (
      next,
      AnswerOutcome(
        starsGained: stars,
        completedSet: completedSet,
        newBadges: List.unmodifiable(unlocked),
      ),
    );
  }

  /// Adds [seconds] of play time to [now]'s day.
  static LearnerProgress applySeconds(
    LearnerProgress progress,
    int seconds,
    DateTime now,
  ) {
    if (seconds <= 0) return progress;
    final day = DayKey.of(now);
    return progress.copyWith(
      dailySeconds: _add(progress.dailySeconds, day, seconds),
    );
  }

  static Map<String, int> _add(Map<String, int> map, String key, int amount) {
    if (amount == 0) return map;
    return {...map, key: (map[key] ?? 0) + amount};
  }
}
