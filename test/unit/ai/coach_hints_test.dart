import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/domain/usecases/coach_hints.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

import '../../helpers/fake_ai.dart';

const _question = ChoiceQuestion(
  id: 'q1',
  subject: Subject.zoology,
  setId: 'mammals',
  prompt: 'Which animal is a mammal?',
  options: [
    AnswerOption(label: 'Shark'),
    AnswerOption(label: 'Dolphin'),
    AnswerOption(label: 'Frog'),
  ],
  answerIndex: 1,
);

void main() {
  group('CoachHints hint', () {
    test('returns a safe hint that keeps the answer secret', () async {
      final llm = FakeLlm(reply: (_, _) => 'Think about who breathes air.');
      final hint = await CoachHints(llm: llm).hint(_question);
      expect(hint, 'Think about who breathes air.');
      expect(llm.users.single, contains('Do NOT say'));
    });

    test('rejects a hint that gives the answer away', () async {
      final llm = FakeLlm(reply: (_, _) => 'It is the Dolphin, of course!');
      expect(await CoachHints(llm: llm).hint(_question), isNull);
    });

    test('rejects text that fails the child-safety check', () async {
      final llm = FakeLlm(reply: (_, _) => 'Some animals fight to survive.');
      expect(await CoachHints(llm: llm).hint(_question), isNull);
    });

    test('cleans dashes and quotation marks before checking', () async {
      final llm = FakeLlm(reply: (_, _) => '"Look for the one — with fur!"');
      expect(
        await CoachHints(llm: llm).hint(_question),
        'Look for the one - with fur!',
      );
    });
  });

  group('CoachHints explain', () {
    test('accepts an explanation that names the right answer', () async {
      final llm = FakeLlm(
        reply: (_, _) => 'A Dolphin feeds its babies milk, so it is a mammal.',
      );
      final text = await CoachHints(llm: llm)
          .explain(_question, chosenIndex: 0);
      expect(text, contains('Dolphin'));
      expect(llm.users.single, contains('picked "Shark"'));
    });

    test('rejects an explanation that never names the answer', () async {
      final llm = FakeLlm(reply: (_, _) => 'Sharks are fish, not mammals.');
      expect(
        await CoachHints(llm: llm).explain(_question, chosenIndex: 0),
        isNull,
      );
    });

    test('talks about a correct answer without blaming anyone', () async {
      final llm = FakeLlm(reply: (_, _) => 'Yes, a Dolphin is a mammal!');
      await CoachHints(llm: llm).explain(_question, chosenIndex: 1);
      expect(llm.users.single, contains('answered correctly'));
    });
  });

  group('CoachHints availability', () {
    test('does nothing when the model is not ready', () async {
      final llm = FakeLlm(ready: false, reply: (_, _) => 'Hello');
      final coach = CoachHints(llm: llm);
      expect(coach.available, isFalse);
      expect(await coach.hint(_question), isNull);
      expect(llm.users, isEmpty);
    });

    test('does nothing when a grown-up turned the AI off', () async {
      final llm = FakeLlm(reply: (_, _) => 'Think about air.');
      final coach = CoachHints(llm: llm, isEnabled: () => false);
      expect(coach.available, isFalse);
    });

    test('returns null when the model fails', () async {
      final llm = FakeLlm(reply: (_, _) => null);
      expect(await CoachHints(llm: llm).hint(_question), isNull);
    });

    test('asks the model once per question and remembers the answer', () async {
      final llm = FakeLlm(reply: (_, _) => 'Think about who breathes air.');
      final coach = CoachHints(llm: llm);
      await coach.hint(_question);
      await coach.hint(_question);
      expect(llm.users, hasLength(1));
    });

    test('gives up when the model is too slow', () async {
      final coach = CoachHints(
        llm: _SlowLlm(),
        timeout: const Duration(milliseconds: 20),
      );
      expect(await coach.hint(_question), isNull);
    });
  });
}

class _SlowLlm implements LlmClient {
  @override
  bool get isReady => true;

  @override
  Future<Result<String>> complete({
    required String system,
    required String user,
    Map<String, Object?>? jsonSchema,
    int maxOutputTokens = 400,
    double temperature = 0.7,
  }) => Completer<Result<String>>().future;

  @override
  Future<void> release() async {}
}
