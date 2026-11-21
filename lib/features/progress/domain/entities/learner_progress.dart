import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';

/// Everything the app remembers about a child's learning. Immutable.
class LearnerProgress extends Equatable {
  const LearnerProgress({
    this.stars = 0,
    this.setCursor = const {},
    this.completedSetIds = const {},
    this.completedSubjects = const {},
    this.correctQuestionIds = const {},
    this.dailyStars = const {},
    this.dailySeconds = const {},
    this.activeDays = const {},
    this.badges = const {},
    this.bestStreak = 0,
    this.currentRun = 0,
    this.bestRun = 0,
    this.setRounds = const {},
  });

  factory LearnerProgress.fromJson(Map<String, Object?> json) {
    Map<String, int> intMap(Object? raw) => {
      for (final e in (raw as Map<Object?, Object?>? ?? const {}).entries)
        if (e.key is String && e.value is int)
          e.key! as String: e.value! as int,
    };
    Set<String> strings(Object? raw) => {
      ...(raw as List<Object?>? ?? const []).whereType<String>(),
    };

    return LearnerProgress(
      stars: json['stars'] as int? ?? 0,
      setCursor: intMap(json['setCursor']),
      completedSetIds: strings(json['completedSetIds']),
      completedSubjects: {
        for (final s in strings(json['completedSubjects']))
          if (Subject.tryParse(s) != null) Subject.tryParse(s)!,
      },
      correctQuestionIds: strings(json['correctQuestionIds']),
      dailyStars: intMap(json['dailyStars']),
      dailySeconds: intMap(json['dailySeconds']),
      activeDays: strings(json['activeDays']),
      badges: {
        for (final b in strings(json['badges']))
          if (BadgeId.tryParse(b) != null) BadgeId.tryParse(b)!,
      },
      bestStreak: json['bestStreak'] as int? ?? 0,
      currentRun: json['currentRun'] as int? ?? 0,
      bestRun: json['bestRun'] as int? ?? 0,
      setRounds: intMap(json['setRounds']),
    );
  }

  final int stars;

  /// Questions already answered in a set that is in progress.
  final Map<String, int> setCursor;
  final Set<String> completedSetIds;
  final Set<Subject> completedSubjects;
  final Set<String> correctQuestionIds;

  /// Stars earned per local day (`yyyy-MM-dd`).
  final Map<String, int> dailyStars;

  /// Seconds played per local day.
  final Map<String, int> dailySeconds;
  final Set<String> activeDays;
  final Set<BadgeId> badges;
  final int bestStreak;

  /// Consecutive correct answers right now and the best ever.
  final int currentRun;
  final int bestRun;

  /// How many times each set has been completed (selects fresh questions).
  final Map<String, int> setRounds;

  /// Questions the child has finished in a set (full length once completed).
  int doneIn(String setId, int setLength) {
    if (completedSetIds.contains(setId)) return setLength;
    return (setCursor[setId] ?? 0).clamp(0, setLength);
  }

  LearnerProgress copyWith({
    int? stars,
    Map<String, int>? setCursor,
    Set<String>? completedSetIds,
    Set<Subject>? completedSubjects,
    Set<String>? correctQuestionIds,
    Map<String, int>? dailyStars,
    Map<String, int>? dailySeconds,
    Set<String>? activeDays,
    Set<BadgeId>? badges,
    int? bestStreak,
    int? currentRun,
    int? bestRun,
    Map<String, int>? setRounds,
  }) {
    return LearnerProgress(
      stars: stars ?? this.stars,
      setCursor: setCursor ?? this.setCursor,
      completedSetIds: completedSetIds ?? this.completedSetIds,
      completedSubjects: completedSubjects ?? this.completedSubjects,
      correctQuestionIds: correctQuestionIds ?? this.correctQuestionIds,
      dailyStars: dailyStars ?? this.dailyStars,
      dailySeconds: dailySeconds ?? this.dailySeconds,
      activeDays: activeDays ?? this.activeDays,
      badges: badges ?? this.badges,
      bestStreak: bestStreak ?? this.bestStreak,
      currentRun: currentRun ?? this.currentRun,
      bestRun: bestRun ?? this.bestRun,
      setRounds: setRounds ?? this.setRounds,
    );
  }

  Map<String, Object?> toJson() => {
    'stars': stars,
    'setCursor': setCursor,
    'completedSetIds': completedSetIds.toList()..sort(),
    'completedSubjects': completedSubjects.map((s) => s.name).toList(),
    'correctQuestionIds': correctQuestionIds.toList()..sort(),
    'dailyStars': dailyStars,
    'dailySeconds': dailySeconds,
    'activeDays': activeDays.toList()..sort(),
    'badges': badges.map((b) => b.name).toList(),
    'bestStreak': bestStreak,
    'currentRun': currentRun,
    'bestRun': bestRun,
    'setRounds': setRounds,
  };

  @override
  List<Object?> get props => [
    stars,
    setCursor,
    completedSetIds,
    completedSubjects,
    correctQuestionIds,
    dailyStars,
    dailySeconds,
    activeDays,
    badges,
    bestStreak,
    currentRun,
    bestRun,
    setRounds,
  ];
}
