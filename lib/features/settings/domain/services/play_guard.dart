import 'package:equatable/equatable.dart';
import 'package:wonderly/core/constants/app_constants.dart';

/// Why play is not allowed right now.
enum BreakReason { dailyLimit, bedtime }

/// Result of a play-time check.
sealed class PlayAllowance extends Equatable {
  const PlayAllowance();

  @override
  List<Object?> get props => const [];
}

/// Play may continue; [remaining] is time left today, or `null` if unlimited.
final class PlayAllowed extends PlayAllowance {
  const PlayAllowed(this.remaining);

  final Duration? remaining;

  @override
  List<Object?> get props => [remaining];
}

/// Play must stop for [reason].
final class PlayBlocked extends PlayAllowance {
  const PlayBlocked(this.reason);

  final BreakReason reason;

  @override
  List<Object?> get props => [reason];
}

/// Decides whether a child may play, from parent-set limits.
abstract final class PlayGuard {
  /// Whether [now] falls in the bedtime window (19:30 to 06:00 by default).
  static bool isBedtime(DateTime now) {
    final minute = now.hour * 60 + now.minute;
    return minute >= AppConstants.bedtimeStartMinuteOfDay ||
        minute < AppConstants.bedtimeEndMinuteOfDay;
  }

  static PlayAllowance check({
    required DateTime now,
    required int secondsPlayedToday,
    required int dailyLimitMinutes,
    required bool bedtimeMode,
  }) {
    if (bedtimeMode && isBedtime(now)) {
      return const PlayBlocked(BreakReason.bedtime);
    }
    final remaining = dailyLimitMinutes * 60 - secondsPlayedToday;
    if (remaining <= 0) return const PlayBlocked(BreakReason.dailyLimit);
    return PlayAllowed(Duration(seconds: remaining));
  }
}
