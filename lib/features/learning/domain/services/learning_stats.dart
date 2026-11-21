import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';

/// Read-only calculations that combine content and progress.
abstract final class LearningStats {
  /// Questions finished across every set of [subject].
  static int doneIn(Subject subject, Catalog catalog, LearnerProgress p) {
    return catalog
        .setsFor(subject)
        .fold(0, (sum, s) => sum + p.doneIn(s.id, s.length));
  }

  /// Fraction (0..1) of [subject] finished.
  static double fractionIn(
    Subject subject,
    Catalog catalog,
    LearnerProgress p,
  ) {
    final total = catalog.questionCountFor(subject);
    return total == 0 ? 0 : doneIn(subject, catalog, p) / total;
  }

  /// The set the Home "Continue" card should open.
  ///
  /// Prefers a set that is partly done, then the first unfinished open set,
  /// then the first playable set.
  static QuizSet? continueSet(Catalog catalog, LearnerProgress p) {
    final playable = catalog.sets
        .where((s) => !s.isEmpty && !s.isLocked(p.stars))
        .toList();
    if (playable.isEmpty) return null;
    for (final s in playable) {
      if ((p.setCursor[s.id] ?? 0) > 0) return s;
    }
    for (final s in playable) {
      if (!p.completedSetIds.contains(s.id)) return s;
    }
    return playable.first;
  }
}
