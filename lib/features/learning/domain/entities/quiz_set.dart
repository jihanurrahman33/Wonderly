import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

/// An ordered group of questions, for example "Zoology Quiz".
class QuizSet extends Equatable {
  const QuizSet({
    required this.id,
    required this.subject,
    required this.title,
    required this.questions,
    this.art,
    this.unlockStars,
  });

  final String id;
  final Subject subject;
  final String title;

  /// Illustration key used on cards.
  final String? art;

  /// Stars needed to open the set, or `null` when always open.
  final int? unlockStars;
  final List<Question> questions;

  int get length => questions.length;

  bool get isEmpty => questions.isEmpty;

  bool isLocked(int stars) => unlockStars != null && stars < unlockStars!;

  @override
  List<Object?> get props => [id, subject, title, art, unlockStars, questions];
}

/// All quiz content available to the app.
class Catalog extends Equatable {
  const Catalog(this.sets);

  final List<QuizSet> sets;

  QuizSet? setById(String id) {
    for (final s in sets) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<QuizSet> setsFor(Subject subject) =>
      List.unmodifiable(sets.where((s) => s.subject == subject));

  /// Total number of questions in a subject.
  int questionCountFor(Subject subject) =>
      setsFor(subject).fold(0, (sum, s) => sum + s.length);

  @override
  List<Object?> get props => [sets];
}
