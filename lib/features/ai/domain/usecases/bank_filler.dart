import 'dart:math';

import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';
import 'package:wonderly/features/ai/domain/repositories/generated_bank_repository.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/domain/usecases/question_generator.dart';
import 'package:wonderly/features/learning/domain/entities/set_blueprint.dart';

/// Progress of a background generation run.
class FillProgress {
  const FillProgress({required this.made, required this.wanted, this.setTitle});

  final int made;
  final int wanted;
  final String? setTitle;
}

/// Tops up the on-device question bank, one question at a time.
///
/// Runs in the background, never while a child waits on a question. Every
/// accepted question is saved immediately, so cancelling loses nothing.
class BankFiller {
  BankFiller({
    required LlmClient llm,
    required GeneratedBankRepository bank,
    QuestionGenerator? generator,
    this.maxAttemptsPerQuestion = 3,
  }) : _llm = llm,
       _bank = bank,
       _generator = generator ?? QuestionGenerator(llm);

  final LlmClient _llm;
  final GeneratedBankRepository _bank;
  final QuestionGenerator _generator;
  final int maxAttemptsPerQuestion;

  /// How many questions the bank is missing for [sets].
  static int missing(GeneratedBank bank, Iterable<SetBlueprint> sets) {
    var total = 0;
    for (final s in sets) {
      total += max(0, s.bankTarget - bank.countFor(s.id));
    }
    return total;
  }

  /// Fills the bank until every LLM set is at its target, [shouldStop] returns
  /// true, or the model keeps failing. Returns the number of questions added.
  Future<int> fill({
    required int grade,
    required bool Function() shouldStop,
    void Function(FillProgress progress)? onProgress,
    Iterable<SetBlueprint>? sets,
    int? limit,
    Random? random,
  }) async {
    final rng = random ?? Random();
    final targets = (sets ?? Curriculum.llmSets).toList();
    final initial = (await _bank.load()).valueOrNull ?? const GeneratedBank();
    final wanted = min(limit ?? 1 << 30, missing(initial, targets));
    var made = 0;
    var consecutiveFailures = 0;

    while (made < wanted &&
        !shouldStop() &&
        consecutiveFailures < 6 &&
        _llm.isReady) {
      final current = (await _bank.load()).valueOrNull ?? const GeneratedBank();
      final next = _neediest(current, targets);
      if (next == null) break;

      final existing = {
        for (final q in current.questionsFor(next.id))
          QuestionGenerator.normalise(q.prompt),
      };
      var accepted = false;
      for (
        var attempt = 0;
        attempt < maxAttemptsPerQuestion && !shouldStop();
        attempt++
      ) {
        final result = await _generator.generate(
          blueprint: next,
          grade: grade,
          existingPrompts: existing,
          random: rng,
        );
        final question = result.valueOrNull;
        if (question != null) {
          await _bank.update((b) => b.add(question, cap: next.bankTarget));
          made++;
          accepted = true;
          onProgress?.call(
            FillProgress(made: made, wanted: wanted, setTitle: next.title),
          );
          break;
        }
        AppLogger.info(
          'Question rejected for ${next.id}: ${result.failureOrNull?.message}',
        );
      }
      consecutiveFailures = accepted ? 0 : consecutiveFailures + 1;
    }
    await _llm.release();
    return made;
  }

  SetBlueprint? _neediest(GeneratedBank bank, List<SetBlueprint> sets) {
    SetBlueprint? best;
    var bestGap = 0;
    for (final s in sets) {
      final gap = s.bankTarget - bank.countFor(s.id);
      if (gap > bestGap) {
        best = s;
        bestGap = gap;
      }
    }
    return best;
  }
}
