import 'package:equatable/equatable.dart';

/// Animal companion a child picks during profile setup.
enum Buddy {
  cat,
  fox,
  rabbit,
  lion,
  owl;

  /// Lenient lookup used when decoding stored data.
  static Buddy fromName(String? name) =>
      Buddy.values.firstWhere((b) => b.name == name, orElse: () => Buddy.cat);
}

/// A child using the app. Several learners can share one device.
class LearnerProfile extends Equatable {
  const LearnerProfile({
    required this.name,
    required this.grade,
    required this.buddy,
    this.id = legacyId,
  });

  factory LearnerProfile.fromJson(Map<String, Object?> json) {
    return LearnerProfile(
      id: json['id'] as String? ?? legacyId,
      name: json['name'] as String? ?? '',
      grade: json['grade'] as int? ?? 1,
      buddy: Buddy.fromName(json['buddy'] as String?),
    );
  }

  /// Id given to the single learner of versions that predate multiple learners.
  static const legacyId = 'legacy';

  final String id;
  final String name;
  final int grade;
  final Buddy buddy;

  LearnerProfile copyWith({String? name, int? grade, Buddy? buddy}) {
    return LearnerProfile(
      id: id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      buddy: buddy ?? this.buddy,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'grade': grade,
    'buddy': buddy.name,
  };

  @override
  List<Object?> get props => [id, name, grade, buddy];
}

/// Every learner on this device and which one is playing.
class LearnerRoster extends Equatable {
  const LearnerRoster({this.learners = const [], this.activeId});

  factory LearnerRoster.fromJson(Map<String, Object?> json) {
    final raw = json['learners'];
    final learners = <LearnerProfile>[
      if (raw is List<Object?>)
        for (final item in raw)
          if (item is Map<String, Object?>) LearnerProfile.fromJson(item),
    ];
    final active = json['activeId'] as String?;
    return LearnerRoster(
      learners: List.unmodifiable(learners),
      activeId: learners.any((l) => l.id == active)
          ? active
          : (learners.isEmpty ? null : learners.first.id),
    );
  }

  final List<LearnerProfile> learners;
  final String? activeId;

  LearnerProfile? get active {
    for (final l in learners) {
      if (l.id == activeId) return l;
    }
    return null;
  }

  /// Adds [profile], or replaces the learner with the same id, and makes it
  /// the active learner.
  LearnerRoster upsertActive(LearnerProfile profile) {
    final exists = learners.any((l) => l.id == profile.id);
    return LearnerRoster(
      learners: List.unmodifiable([
        for (final l in learners) l.id == profile.id ? profile : l,
        if (!exists) profile,
      ]),
      activeId: profile.id,
    );
  }

  LearnerRoster withActive(String id) => learners.any((l) => l.id == id)
      ? LearnerRoster(learners: learners, activeId: id)
      : this;

  LearnerRoster without(String id) {
    final rest = learners.where((l) => l.id != id).toList();
    return LearnerRoster(
      learners: List.unmodifiable(rest),
      activeId: activeId == id
          ? (rest.isEmpty ? null : rest.first.id)
          : activeId,
    );
  }

  Map<String, Object?> toJson() => {
    'learners': learners.map((l) => l.toJson()).toList(),
    'activeId': activeId,
  };

  @override
  List<Object?> get props => [learners, activeId];
}
