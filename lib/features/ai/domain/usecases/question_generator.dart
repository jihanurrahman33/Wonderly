import 'dart:convert';
import 'dart:math';

import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/stable_hash.dart';
import 'package:wonderly/features/ai/domain/services/content_safety.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/set_blueprint.dart';
import 'package:wonderly/features/learning/domain/usecases/validate_question.dart';

/// Asks the on-device model for one quiz question and only returns it if it
/// passes every gate:
///
/// 1. the reply is a single JSON object with the expected fields,
/// 2. the structure passes [ValidateQuestion],
/// 3. all text passes [ContentSafety],
/// 4. it is not a duplicate of an existing question,
/// 5. a **second model pass answers the question without seeing the key** and
///    must pick the same option.
class QuestionGenerator {
  const QuestionGenerator(
    this._llm, {
    ContentSafety safety = const ContentSafety(),
    ValidateQuestion validate = const ValidateQuestion(),
  }) : _safety = safety,
       _validate = validate;

  final LlmClient _llm;
  final ContentSafety _safety;
  final ValidateQuestion _validate;

  /// JSON schema sent to engines that can constrain their output.
  static const schema = <String, Object?>{
    'type': 'object',
    'properties': {
      'question': {'type': 'string'},
      'options': {
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 4,
        'maxItems': 4,
      },
      'answer': {'type': 'integer', 'minimum': 0, 'maximum': 3},
      'hint': {'type': 'string'},
      'fact': {'type': 'string'},
    },
    'required': ['question', 'options', 'answer', 'hint', 'fact'],
    'additionalProperties': false,
  };

  Future<Result<ChoiceQuestion>> generate({
    required SetBlueprint blueprint,
    required int grade,
    required Set<String> existingPrompts,
    required Random random,
  }) async {
    final reply = await _llm.complete(
      system: _systemPrompt,
      user: _userPrompt(blueprint, grade, existingPrompts),
      jsonSchema: schema,
      maxOutputTokens: 320,
      temperature: 0.8,
    );
    final text = reply.valueOrNull;
    if (text == null) {
      return Result.failure(
        reply.failureOrNull ?? const DataFailure('No reply.'),
      );
    }

    final draft = _parse(text);
    if (draft == null) {
      return const Result.failure(DataFailure('Reply was not valid.'));
    }

    for (final part in [
      draft.question,
      draft.hint,
      draft.fact,
      ...draft.options,
    ]) {
      final problem = _safety.check(part);
      if (problem != null) {
        return Result.failure(DataFailure('Unsafe: $problem'));
      }
    }
    if (existingPrompts.contains(_normalise(draft.question))) {
      return const Result.failure(DataFailure('Duplicate question.'));
    }

    // Shuffle so the right answer is not always where the model likes to put it.
    final order = List<int>.generate(4, (i) => i)..shuffle(random);
    final options = [for (final i in order) draft.options[i]];
    final answerIndex = order.indexOf(draft.answer);
    final question = ChoiceQuestion(
      id: 'gen-${blueprint.id}-${StableHash.of(_normalise(draft.question))}',
      subject: blueprint.subject,
      setId: blueprint.id,
      prompt: draft.question,
      options: [for (final o in options) AnswerOption(label: o)],
      answerIndex: answerIndex,
      layout: ChoiceLayout.textList,
      hint: draft.hint,
      fact: draft.fact,
    );

    final structural = _validate(question);
    if (structural != null) {
      return Result.failure(DataFailure('Invalid: $structural'));
    }

    final agrees = await _modelAgrees(question);
    if (!agrees) {
      return const Result.failure(DataFailure('Self-check disagreed.'));
    }
    return Result.success(question);
  }

  /// Second pass: the model solves the question without the answer key.
  Future<bool> _modelAgrees(ChoiceQuestion q) async {
    final numbered = [
      for (var i = 0; i < q.options.length; i++)
        '${i + 1}. ${q.options[i].label}',
    ].join('\n');
    final reply = await _llm.complete(
      system:
          'You answer multiple choice questions for children. '
          'Reply with only the number of the correct option: 1, 2, 3 or 4.',
      user: '${q.prompt}\n$numbered',
      maxOutputTokens: 4,
      temperature: 0.1,
    );
    final text = reply.valueOrNull;
    if (text == null) return false;
    final digit = RegExp(r'[1-4]').firstMatch(text)?.group(0);
    return digit != null && int.parse(digit) - 1 == q.answerIndex;
  }

  _Draft? _parse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final json = jsonDecode(raw.substring(start, end + 1));
      if (json is! Map<String, Object?>) return null;
      final question = json['question'];
      final options = json['options'];
      final answer = json['answer'];
      final hint = json['hint'];
      final fact = json['fact'];
      if (question is! String || hint is! String || fact is! String) {
        return null;
      }
      if (options is! List<Object?> || options.length != 4) return null;
      if (options.any((o) => o is! String)) return null;
      final intAnswer = answer is num && answer == answer.toInt()
          ? answer.toInt()
          : null;
      if (intAnswer == null || intAnswer < 0 || intAnswer > 3) return null;
      return _Draft(
        question: question.trim(),
        options: [for (final o in options) (o! as String).trim()],
        answer: intAnswer,
        hint: hint.trim(),
        fact: fact.trim(),
      );
    } on FormatException {
      return null;
    }
  }

  static String _normalise(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Normalised form used to compare prompts for duplicates.
  static String normalise(String s) => _normalise(s);

  static const _systemPrompt =
      'You write multiple choice quiz questions for children aged 6 to 11. '
      'Every fact must be true and widely agreed. Use simple words. Never use '
      'scary, violent, adult or controversial content. Reply with one JSON '
      'object only: {"question": string, "options": [4 different short '
      'strings], "answer": index 0 to 3 of the correct option, "hint": a '
      'short helpful clue that does not give the answer away, "fact": one '
      'friendly sentence explaining why the answer is right}. The question '
      'must have 15 words or fewer and exactly one correct option.';

  String _userPrompt(SetBlueprint b, int grade, Set<String> existing) {
    final avoid = existing.take(8).join(' | ');
    return 'Write one new question for a child in grade $grade about '
        '${b.topic}.${avoid.isEmpty ? '' : ' Do not repeat these: $avoid.'}';
  }
}

class _Draft {
  const _Draft({
    required this.question,
    required this.options,
    required this.answer,
    required this.hint,
    required this.fact,
  });

  final String question;
  final List<String> options;
  final int answer;
  final String hint;
  final String fact;
}
