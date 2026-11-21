/// Display formatting shared across screens.
abstract final class Formatters {
  /// `1` becomes `1st`, `2` becomes `2nd`, and so on.
  static String ordinal(int n) {
    final lastTwo = n % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  /// `7800` seconds becomes `2h 10m`; under an hour becomes `45m`.
  static String duration(int seconds) {
    final totalMinutes = seconds ~/ 60;
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  /// `Grade label` such as `3rd Grade`.
  static String grade(int grade) => '${ordinal(grade)} Grade';
}
