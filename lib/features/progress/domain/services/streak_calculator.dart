import 'package:wonderly/core/utils/clock.dart';

/// Computes consecutive-day play streaks.
abstract final class StreakCalculator {
  /// Current streak ending today, or yesterday when the child has not played
  /// yet today (so the streak is still alive until the day ends).
  static int current(Set<String> activeDays, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var cursor = activeDays.contains(DayKey.of(today))
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    var count = 0;
    while (activeDays.contains(DayKey.of(cursor))) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// Whether the child has already played on [now]'s calendar day.
  static bool playedToday(Set<String> activeDays, DateTime now) =>
      activeDays.contains(DayKey.of(now));
}
