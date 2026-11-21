import 'dart:math';

import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/core/utils/stable_hash.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/set_blueprint.dart';
import 'package:wonderly/features/learning/domain/services/procedural_generator.dart';

/// Builds the playable [Catalog] from the curriculum.
///
/// - Procedural sets are generated on the spot from the learner's grade.
/// - LLM sets use questions the on-device model wrote. Each completed round
///   moves to the next window of the bank, so a replay is never identical.
/// - The small bundled seed bank is only a safety net until the model has
///   written enough questions (first run, no model, or an unsupported phone).
class CatalogAssembler {
  const CatalogAssembler([this._procedural = const ProceduralGenerator()]);

  final ProceduralGenerator _procedural;

  Catalog assemble({
    required Catalog seed,
    required GeneratedBank bank,
    required int grade,
    required Map<String, int> rounds,
    required DateTime now,
  }) {
    final daySeed = int.parse(DayKey.of(now).replaceAll('-', ''));
    final sets = <QuizSet>[];
    for (final b in Curriculum.blueprints) {
      final round = rounds[b.id] ?? 0;
      final questions = switch (b.source) {
        QuestionSource.procedural => _procedure(b, grade, daySeed, round),
        QuestionSource.llm => _fromBank(b, bank, seed, round),
      };
      sets.add(
        QuizSet(
          id: b.id,
          subject: b.subject,
          title: b.title,
          art: b.art,
          unlockStars: b.unlockStars,
          questions: List.unmodifiable(questions),
        ),
      );
    }
    return Catalog(List.unmodifiable(sets));
  }

  List<Question> _procedure(SetBlueprint b, int grade, int daySeed, int round) {
    final random = Random(
      daySeed * 31 +
          grade * 7 +
          round * 101 +
          int.parse(StableHash.of(b.id), radix: 16) % 9973,
    );
    return switch (b.id) {
      'logic_puzzles' => _procedural.patterns(b.id, b.quizSize, random),
      'geometry_shapes' => _procedural.geometry(
        b.id,
        b.quizSize,
        random,
        grade,
      ),
      _ => _procedural.numbers(b.id, b.quizSize, random, grade),
    };
  }

  List<Question> _fromBank(
    SetBlueprint b,
    GeneratedBank bank,
    Catalog seed,
    int round,
  ) {
    final pool = bank.questionsFor(b.id);
    final windows = pool.length ~/ b.quizSize;
    if (windows >= 1) {
      final start = (round % windows) * b.quizSize;
      return pool.sublist(start, start + b.quizSize);
    }
    final fallback = seed.setById(b.id)?.questions ?? const <Question>[];
    final padded = <Question>[...pool];
    for (final q in fallback) {
      if (padded.length >= b.quizSize) break;
      padded.add(q);
    }
    return padded;
  }
}
