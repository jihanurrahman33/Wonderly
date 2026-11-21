/// Tunable product rules. Keep magic numbers here, not in widgets.
abstract final class AppConstants {
  static const appName = 'Wonderly';
  static const appVersionLabel = 'Wonderly 1.0';

  static const minGrade = 1;
  static const maxGrade = 5;
  static const maxNameLength = 20;

  /// Stars awarded the first time a question is answered correctly.
  static const starsPerCorrectAnswer = 1;

  /// Stars awarded the first time a quiz set is completed.
  static const starsForFirstCompletion = 4;

  /// Stars awarded when a badge unlocks.
  static const starsPerBadge = 5;

  /// Stars needed to unlock the Plant Pal badge and locked quiz sets.
  static const starsForPlantPal = 30;

  static const quickThinkerRun = 5;
  static const weekWarriorStreak = 7;

  static const defaultDailyLimitMinutes = 30;
  static const minDailyLimitMinutes = 10;
  static const maxDailyLimitMinutes = 60;
  static const dailyLimitStepMinutes = 5;
  static const weeklyGoalMinutes = 180;

  /// Bedtime mode blocks play from this local time (19:30) until 06:00.
  static const bedtimeStartMinuteOfDay = 19 * 60 + 30;
  static const bedtimeEndMinuteOfDay = 6 * 60;

  static const parentGateMaxAttempts = 3;
  static const parentGateLockout = Duration(seconds: 30);

  static const playTickInterval = Duration(seconds: 1);
}
