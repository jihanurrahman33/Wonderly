import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/features/settings/domain/services/play_guard.dart';

PlayAllowance check({
  DateTime? now,
  int played = 0,
  int limit = 30,
  bool bedtime = false,
}) {
  return PlayGuard.check(
    now: now ?? DateTime(2026, 11, 21, 15),
    secondsPlayedToday: played,
    dailyLimitMinutes: limit,
    bedtimeMode: bedtime,
  );
}

void main() {
  group('PlayGuard', () {
    test('allows play and reports the time left', () {
      expect(check(played: 10 * 60), const PlayAllowed(Duration(minutes: 20)));
    });

    test('blocks exactly when the daily limit is reached', () {
      expect(check(played: 30 * 60 - 1), isA<PlayAllowed>());
      expect(check(played: 30 * 60), const PlayBlocked(BreakReason.dailyLimit));
      expect(check(played: 31 * 60), const PlayBlocked(BreakReason.dailyLimit));
    });

    test('blocks during bedtime only when bedtime mode is on', () {
      final late = DateTime(2026, 11, 21, 19, 30);
      expect(
        check(now: late, bedtime: true),
        const PlayBlocked(BreakReason.bedtime),
      );
      expect(check(now: late), isA<PlayAllowed>());
    });

    test('bedtime window covers late evening and early morning', () {
      expect(PlayGuard.isBedtime(DateTime(2026, 1, 1, 19, 29)), isFalse);
      expect(PlayGuard.isBedtime(DateTime(2026, 1, 1, 19, 30)), isTrue);
      expect(PlayGuard.isBedtime(DateTime(2026, 1, 1, 23, 59)), isTrue);
      expect(PlayGuard.isBedtime(DateTime(2026, 1, 1, 5, 59)), isTrue);
      expect(PlayGuard.isBedtime(DateTime(2026, 1, 1, 6)), isFalse);
    });

    test('bedtime takes priority over the daily limit message', () {
      final result = check(
        now: DateTime(2026, 11, 21, 21),
        played: 99999,
        bedtime: true,
      );
      expect(result, const PlayBlocked(BreakReason.bedtime));
    });
  });
}
