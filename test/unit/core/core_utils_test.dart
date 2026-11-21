import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/core/utils/formatters.dart';

void main() {
  group('DayKey', () {
    test('formats dates as zero padded yyyy-MM-dd', () {
      expect(DayKey.of(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('parses its own output and rejects malformed keys', () {
      expect(DayKey.parse('2026-03-07'), DateTime(2026, 3, 7));
      expect(DayKey.parse('nonsense'), isNull);
      expect(DayKey.parse('2026-xx-07'), isNull);
    });

    test('lastDays returns days ending today, oldest first', () {
      final days = DayKey.lastDays(DateTime(2026, 3, 2), 3);
      expect(days.map(DayKey.of), ['2026-02-28', '2026-03-01', '2026-03-02']);
    });

    test('weekOf starts on Monday', () {
      // 2026-11-21 is a Saturday.
      final week = DayKey.weekOf(DateTime(2026, 11, 21));
      expect(DayKey.of(week.first), '2026-11-16');
      expect(DayKey.of(week.last), '2026-11-22');
      expect(week.first.weekday, DateTime.monday);
    });
  });

  group('Formatters', () {
    test('ordinal handles 1st, 2nd, 3rd and teens', () {
      expect(Formatters.ordinal(1), '1st');
      expect(Formatters.ordinal(2), '2nd');
      expect(Formatters.ordinal(3), '3rd');
      expect(Formatters.ordinal(4), '4th');
      expect(Formatters.ordinal(11), '11th');
      expect(Formatters.ordinal(12), '12th');
    });

    test('duration shows hours and minutes', () {
      expect(Formatters.duration(7800), '2h 10m');
      expect(Formatters.duration(45 * 60), '45m');
      expect(Formatters.duration(0), '0m');
    });
  });

  group('Result', () {
    test('fold picks the matching branch', () {
      const ok = Result<int>.success(2);
      const bad = Result<int>.failure(StorageFailure('nope'));
      expect(ok.fold(onSuccess: (v) => v * 2, onFailure: (_) => -1), 4);
      expect(bad.fold(onSuccess: (v) => v, onFailure: (f) => -1), -1);
      expect(ok.valueOrNull, 2);
      expect(ok.failureOrNull, isNull);
      expect(bad.valueOrNull, isNull);
      expect(bad.failureOrNull, const StorageFailure('nope'));
    });
  });
}
