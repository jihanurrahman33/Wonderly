import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/services/streak_calculator.dart';

/// Pure rules deciding which badges a child has earned.
abstract final class BadgeRules {
  /// Whether [badge] is earned given [progress] at time [now].
  static bool isEarned(BadgeId badge, LearnerProgress progress, DateTime now) {
    return switch (badge) {
      BadgeId.zoologyExplorer => progress.completedSubjects.contains(
        Subject.zoology,
      ),
      BadgeId.shapeStarter => progress.completedSubjects.contains(
        Subject.geometry,
      ),
      BadgeId.quickThinker => progress.bestRun >= AppConstants.quickThinkerRun,
      BadgeId.plantPal => progress.stars >= AppConstants.starsForPlantPal,
      BadgeId.puzzlePro => progress.completedSubjects.contains(Subject.logic),
      BadgeId.weekWarrior =>
        StreakCalculator.current(progress.activeDays, now) >=
            AppConstants.weekWarriorStreak,
    };
  }

  /// Badges earned by [progress] that it does not hold yet, in catalog order.
  static List<BadgeId> newlyEarned(LearnerProgress progress, DateTime now) {
    return [
      for (final b in BadgeId.values)
        if (!progress.badges.contains(b) && isEarned(b, progress, now)) b,
    ];
  }

  /// Fraction (0 to 1) of progress toward Plant Pal for the rewards header.
  static double plantPalFraction(int stars) =>
      (stars / AppConstants.starsForPlantPal).clamp(0.0, 1.0);

  /// The weekday-aligned day keys for the streak strip, oldest first.
  static List<String> weekKeys(DateTime now) =>
      DayKey.lastDays(now, 7).map(DayKey.of).toList();
}
