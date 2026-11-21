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

/// The child using the app.
class LearnerProfile extends Equatable {
  const LearnerProfile({
    required this.name,
    required this.grade,
    required this.buddy,
  });

  factory LearnerProfile.fromJson(Map<String, Object?> json) {
    return LearnerProfile(
      name: json['name'] as String? ?? '',
      grade: json['grade'] as int? ?? 1,
      buddy: Buddy.fromName(json['buddy'] as String?),
    );
  }

  final String name;
  final int grade;
  final Buddy buddy;

  Map<String, Object?> toJson() => {
    'name': name,
    'grade': grade,
    'buddy': buddy.name,
  };

  @override
  List<Object?> get props => [name, grade, buddy];
}
