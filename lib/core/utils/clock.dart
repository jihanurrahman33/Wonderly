/// Source of the current time. Injected so time-based rules are testable.
abstract interface class Clock {
  DateTime now();
}

/// [Clock] backed by the device clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Calendar-day helpers shared by streak, limit and report logic.
abstract final class DayKey {
  /// Local calendar day as `yyyy-MM-dd`.
  static String of(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses a key produced by [of]; returns `null` for malformed input.
  static DateTime? parse(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// The [days] most recent calendar days ending at [today], oldest first.
  static List<DateTime> lastDays(DateTime today, int days) {
    final base = DateTime(today.year, today.month, today.day);
    return List.unmodifiable([
      for (var i = days - 1; i >= 0; i--)
        DateTime(base.year, base.month, base.day - i),
    ]);
  }

  /// The seven days of the calendar week containing [date], Monday first.
  static List<DateTime> weekOf(DateTime date) {
    final base = DateTime(date.year, date.month, date.day);
    final monday = DateTime(
      base.year,
      base.month,
      base.day - (base.weekday - 1),
    );
    return List.unmodifiable([
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ]);
  }
}
