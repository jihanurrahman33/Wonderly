import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/utils/stable_hash.dart';
import 'package:wonderly/features/ai/data/generated_bank_repository_impl.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';
import 'package:wonderly/features/ai/domain/services/content_safety.dart';
import 'package:wonderly/features/ai/domain/usecases/a2ui_validator.dart';
import 'package:wonderly/features/ai/domain/usecases/bank_filler.dart';
import 'package:wonderly/features/ai/domain/usecases/question_generator.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/set_blueprint.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/catalog_assembler.dart';
import 'package:wonderly/features/learning/domain/services/procedural_generator.dart';
import 'package:wonderly/features/learning/domain/usecases/validate_question.dart';

import '../../helpers/fake_ai.dart';
import '../../helpers/fakes.dart';

final mammals = Curriculum.byId('mammals')!;

void main() {
  geometryVarietyTests();
  group('ContentSafety', () {
    const safety = ContentSafety();

    test('accepts friendly text', () {
      expect(safety.check('Which animal says moo?'), isNull);
      expect(safety.check('7 × 6 = 42'), isNull);
    });

    test('rejects blocked words, links and odd characters', () {
      expect(safety.check('The lion will kill the zebra'), contains('kill'));
      expect(safety.check('Visit http://x.com'), isNotNull);
      expect(safety.check('Hello 😀'), 'unexpected characters');
      expect(safety.check('   '), 'empty text');
      expect(safety.check('a' * 300), 'text too long');
    });

    test('matches whole words only', () {
      expect(safety.check('A skill game'), isNull);
    });
  });

  test('StableHash is deterministic and spreads values', () {
    expect(StableHash.of('abc'), StableHash.of('abc'));
    expect(StableHash.of('abc'), isNot(StableHash.of('abd')));
    expect(StableHash.of('abc'), hasLength(8));
  });

  group('QuestionGenerator', () {
    late FakeLlm llm;
    late QuestionGenerator generator;

    setUp(() {
      llm = FakeLlm();
      generator = QuestionGenerator(llm);
    });

    Future<String?> run({Set<String> existing = const {}}) async {
      final result = await generator.generate(
        blueprint: mammals,
        grade: 3,
        existingPrompts: existing,
        random: Random(1),
      );
      return result.failureOrNull?.message;
    }

    test(
      'accepts a valid question when the model agrees with itself',
      () async {
        // The second (self-check) call answers with the 1-based position of the
        // correct option, found by asking for the same text.
        llm.reply = (system, user) {
          if (system.startsWith('You answer')) {
            final lines = user.split('\n');
            final options = lines.skip(1).toList();
            final cow = options.indexWhere((l) => l.endsWith('Cow'));
            return '${cow + 1}';
          }
          return questionReply();
        };
        final result = await generator.generate(
          blueprint: mammals,
          grade: 3,
          existingPrompts: {},
          random: Random(3),
        );
        final q = result.valueOrNull!;
        expect(q.setId, 'mammals');
        expect(q.options[q.answerIndex].label, 'Cow');
        expect(q.options.map((o) => o.label).toSet(), {
          'Cow',
          'Dog',
          'Cat',
          'Duck',
        });
        expect(q.id, startsWith('gen-mammals-'));
        expect(q.layout, ChoiceLayout.textList);
      },
    );

    test('rejects a question when the self-check disagrees', () async {
      llm.reply = (system, user) =>
          system.startsWith('You answer') ? '9' : questionReply();
      expect(await run(), 'Self-check disagreed.');
    });

    test('rejects replies that are not JSON or have the wrong shape', () async {
      for (final bad in [
        'sorry I cannot',
        '{"question": "x"}',
        questionReply(options: const ['A', 'B', 'C']),
        questionReply(answer: 7),
        '{"question": 3, "options": [], "answer": 0, "hint": "", "fact": ""}',
      ]) {
        llm.reply = (_, _) => bad;
        expect(await run(), isNotNull, reason: bad);
      }
    });

    test('rejects duplicate options and unsafe text', () async {
      llm.reply = (_, _) =>
          questionReply(options: const ['Cow', 'Cow', 'Cat', 'Dog']);
      expect(await run(), contains('duplicate'));
      llm.reply = (_, _) => questionReply(fact: 'Wolves kill sheep.');
      expect(await run(), contains('Unsafe'));
    });

    test('rejects prompts that are too long', () async {
      llm.reply = (_, _) =>
          questionReply(question: List.filled(20, 'word').join(' '));
      expect(await run(), contains('Invalid'));
    });

    test('rejects a duplicate of an existing question', () async {
      llm.reply = (_, _) => questionReply();
      final existing = {QuestionGenerator.normalise('Which animal says moo?')};
      expect(await run(existing: existing), 'Duplicate question.');
    });

    test('passes the model failure through', () async {
      llm.reply = (_, _) => null;
      expect(await run(), 'fake failure');
    });

    test('extracts JSON from chatter around it', () async {
      llm.reply = (system, user) => system.startsWith('You answer')
          ? '1'
          : 'Sure! Here you go: ${questionReply()} Hope that helps.';
      // Parsing succeeds; the self-check outcome depends on the shuffle, so
      // only the parsing stage is asserted: it must not fail as unreadable.
      expect(await run(), isNot('Reply was not valid.'));
    });
  });

  group('BankFiller', () {
    late InMemoryStore store;
    late GeneratedBankRepositoryImpl bank;

    setUp(() {
      store = InMemoryStore();
      bank = GeneratedBankRepositoryImpl(store);
    });

    // A model that is always right: it echoes the position of the right option.
    FakeLlm cooperativeLlm() {
      var n = 0;
      return FakeLlm(
        reply: (system, user) {
          if (system.startsWith('You answer')) {
            final options = user.split('\n').skip(1).toList();
            return '${options.indexWhere((l) => l.contains('Right')) + 1}';
          }
          n++;
          return questionReply(
            question:
                'Question number ${String.fromCharCodes([97 + n % 26, 97 + n ~/ 26])}?',
            options: ['Right', 'Wrong $n', 'Nope $n', 'No $n'],
          );
        },
      );
    }

    test('fills a set to its target and releases the model', () async {
      final llm = cooperativeLlm();
      final filler = BankFiller(llm: llm, bank: bank);
      final made = await filler.fill(
        grade: 3,
        shouldStop: () => false,
        sets: [mammals],
        random: Random(2),
      );
      expect(made, mammals.bankTarget);
      expect(
        (await bank.load()).valueOrNull?.countFor('mammals'),
        mammals.bankTarget,
      );
      expect(llm.released, 1);
    });

    test('respects a limit and can be stopped between questions', () async {
      final filler = BankFiller(llm: cooperativeLlm(), bank: bank);
      expect(
        await filler.fill(
          grade: 3,
          shouldStop: () => false,
          sets: [mammals],
          limit: 3,
        ),
        3,
      );
      var calls = 0;
      final stopped = await filler.fill(
        grade: 3,
        shouldStop: () => ++calls > 1,
        sets: [mammals],
      );
      expect(stopped, lessThanOrEqualTo(1));
    });

    test('gives up after repeated failures instead of looping', () async {
      final llm = FakeLlm(reply: (_, _) => 'garbage');
      final filler = BankFiller(
        llm: llm,
        bank: bank,
        maxAttemptsPerQuestion: 2,
      );
      expect(
        await filler.fill(grade: 3, shouldStop: () => false, sets: [mammals]),
        0,
      );
      expect(llm.users.length, lessThanOrEqualTo(6 * 2));
    });

    test('does nothing when the model is not ready', () async {
      final llm = FakeLlm(ready: false, reply: (_, _) => questionReply());
      final filler = BankFiller(llm: llm, bank: bank);
      expect(
        await filler.fill(grade: 3, shouldStop: () => false, sets: [mammals]),
        0,
      );
      expect(llm.users, isEmpty);
    });

    test('missing counts what each set still needs', () {
      expect(
        BankFiller.missing(const GeneratedBank(), [mammals]),
        mammals.bankTarget,
      );
    });
  });

  group('GeneratedBank', () {
    ChoiceQuestion q(String id, {String set = 'mammals'}) => ChoiceQuestion(
      id: id,
      subject: Subject.zoology,
      setId: set,
      prompt: 'Which is $id?',
      options: const [
        AnswerOption(label: 'A'),
        AnswerOption(label: 'B'),
      ],
      answerIndex: 1,
      layout: ChoiceLayout.textList,
    );

    test('adds, de-duplicates and caps (oldest dropped first)', () {
      var bank = const GeneratedBank();
      for (var i = 0; i < 5; i++) {
        bank = bank.add(q('q$i'), cap: 3);
      }
      expect(bank.questionsFor('mammals').map((e) => e.id), ['q2', 'q3', 'q4']);
      expect(bank.add(q('q4'), cap: 3), bank);
      expect(bank.total, 3);
      expect(bank.idsFor('mammals'), {'q2', 'q3', 'q4'});
    });

    test('round trips through JSON and drops invalid stored questions', () {
      final bank = const GeneratedBank()
          .add(q('a'), cap: 9)
          .add(q('b', set: 'birds'), cap: 9);
      final restored = GeneratedBank.fromJson(bank.toJson());
      expect(restored.countFor('mammals'), 1);
      expect(restored.countFor('birds'), 1);

      final tampered = GeneratedBank.fromJson({
        'sets': {
          'mammals': [
            {
              'id': 'x',
              'subject': 'zoology',
              'prompt': 'Which?',
              'options': ['A', 'A'],
              'answer': 0,
            },
            {
              'id': 'y',
              'subject': 'zoology',
              'prompt': 'Which?',
              'options': ['A', 'B'],
              'answer': 5,
            },
            {
              'id': 'z',
              'subject': 'nope',
              'prompt': 'Which?',
              'options': ['A', 'B'],
              'answer': 0,
            },
            'junk',
          ],
        },
      });
      expect(tampered.total, 0);
    });

    test('repository persists the bank', () async {
      final store = InMemoryStore();
      await GeneratedBankRepositoryImpl(store)
          .update((b) => b.add(q('a'), cap: 9));
      expect(
        (await GeneratedBankRepositoryImpl(store).load()).valueOrNull?.total,
        1,
      );
    });
  });

  group('A2uiValidator', () {
    const validator = A2uiValidator();
    const allowed = {'mammals', 'birds'};

    String message({
      String title = 'Hi Alex!',
      String body = 'Ready for a quiz?',
      String accent = 'sage',
      String setId = 'mammals',
      String name = 'startQuiz',
      bool withButton = true,
    }) {
      final child = withButton ? ',"child":"go"' : '';
      final button = withButton
          ? ',{"id":"go","component":"ActionButton","label":"Play","action":{"event":{"name":"$name","context":{"setId":"$setId"}}}}'
          : '';
      return '{"version":"v0.9","createSurface":{"surfaceId":"buddy","catalogId":"x"}}\n'
          '{"version":"v0.9","updateComponents":{"surfaceId":"buddy","components":['
          '{"id":"root","component":"BuddyCard","accent":"$accent","title":"$title","body":"$body"$child}$button]}}';
    }

    test('accepts a well-formed card with a safe action', () {
      final spec = validator.parse(message(), allowedSetIds: allowed)!;
      expect(spec.title, 'Hi Alex!');
      expect(spec.actionSetId, 'mammals');
      expect(spec.actionLabel, 'Play');
    });

    test('accepts fenced JSON and surrounding chatter', () {
      final wrapped = 'Here you go:\n```json\n${message()}\n```\nEnjoy!';
      expect(validator.parse(wrapped, allowedSetIds: allowed), isNotNull);
    });

    test('card without a button is fine and unknown accents fall back', () {
      final spec = validator.parse(
        message(withButton: false, accent: 'neon'),
        allowedSetIds: allowed,
      )!;
      expect(spec.actionSetId, isNull);
      expect(spec.accent, 'sage');
    });

    test('rejects unknown actions and quiz ids', () {
      expect(
        validator.parse(message(name: 'openUrl'), allowedSetIds: allowed),
        isNull,
      );
      expect(
        validator.parse(message(setId: 'secret'), allowedSetIds: allowed),
        isNull,
      );
    });

    test('rejects unsafe, empty or oversized text', () {
      expect(
        validator.parse(
          message(body: 'Visit http://x.com'),
          allowedSetIds: allowed,
        ),
        isNull,
      );
      expect(
        validator.parse(message(title: ''), allowedSetIds: allowed),
        isNull,
      );
      expect(
        validator.parse(message(body: 'a ' * 200), allowedSetIds: allowed),
        isNull,
      );
    });

    test('rejects replies that are not A2UI', () {
      for (final bad in [
        '',
        'hello',
        '{"a":1}',
        '{"updateComponents":{"components":[1]}}',
      ]) {
        expect(
          validator.parse(bad, allowedSetIds: allowed),
          isNull,
          reason: bad,
        );
      }
    });

    test('rejects a missing root or a non-BuddyCard root', () {
      const noRoot =
          '{"updateComponents":{"components":[{"id":"a","component":"BuddyCard","title":"t","body":"b"}]}}';
      const wrongType =
          '{"updateComponents":{"components":[{"id":"root","component":"Image","url":"x"}]}}';
      expect(validator.parse(noRoot, allowedSetIds: allowed), isNull);
      expect(validator.parse(wrongType, allowedSetIds: allowed), isNull);
    });
  });

  group('ProceduralGenerator', () {
    const gen = ProceduralGenerator();

    test('patterns repeat to exactly the stated answer', () {
      final questions = gen.patterns('logic_puzzles', 40, Random(5));
      expect(questions, hasLength(40));
      for (final q in questions) {
        final answer = q.options[q.answerIndex];
        expect(q.options.toSet(), hasLength(q.options.length));
        // Some period p explains the whole visible sequence and predicts answer.
        final explained = [
          for (var p = 1; p < q.sequence.length; p++)
            if ([
                  for (var i = 0; i < q.sequence.length; i++)
                    q.sequence[i] == q.sequence[i % p],
                ].every((e) => e) &&
                q.sequence[q.sequence.length % p] == answer)
              p,
        ];
        expect(explained, isNotEmpty, reason: '${q.sequence} -> $answer');
        expect(const ValidateQuestionProbe().valid(q), isTrue);
      }
    });

    test('arithmetic answers are exactly right at every grade', () {
      for (var grade = 1; grade <= 5; grade++) {
        final questions = gen.numbers('number_fun', 60, Random(grade), grade);
        expect(questions.length, greaterThan(40));
        for (final q in questions) {
          final m = RegExp(r'^(\d+) ([+−×÷]) (\d+) = \?$')
              .firstMatch(q.prompt)!;
          final a = int.parse(m.group(1)!);
          final b = int.parse(m.group(3)!);
          final expected = switch (m.group(2)) {
            '+' => a + b,
            '−' => a - b,
            '×' => a * b,
            _ => a ~/ b,
          };
          if (m.group(2) == '÷') expect(a % b, 0);
          expect(q.options[q.answerIndex].label, '$expected', reason: q.prompt);
          expect(expected, greaterThan(0));
          expect(q.options.map((o) => o.label).toSet(), hasLength(4));
          expect(const ValidateQuestionProbe().valid(q), isTrue);
        }
      }
    });

    test('grade 1 only adds and subtracts within 10', () {
      for (final q in gen.numbers('n', 50, Random(9), 1)) {
        expect(q.prompt, matches(RegExp(r'^\d{1,2} [+−] \d{1,2} = \?$')));
        final nums = RegExp(r'\d+')
            .allMatches(q.prompt)
            .map((m) => int.parse(m.group(0)!));
        expect(nums.every((n) => n <= 10), isTrue, reason: q.prompt);
      }
    });

    test('geometry questions are valid and facts are true', () {
      for (final grade in [1, 4]) {
        final qs = gen.geometry('geometry_shapes', 40, Random(grade), grade);
        expect(qs, isNotEmpty);
        for (final q in qs) {
          expect(
            const ValidateQuestionProbe().valid(q),
            isTrue,
            reason: q.prompt,
          );
          if (q is ChoiceQuestion && q.prompt.contains('no corners')) {
            expect(q.options[q.answerIndex].label, 'Circle');
          }
          if (q is ChoiceQuestion && q.prompt.startsWith('How many')) {
            final shape = RegExp(r'a (\w+) have')
                .firstMatch(q.prompt)!
                .group(1)!;
            const sides = {
              'triangle': 3,
              'square': 4,
              'pentagon': 5,
              'hexagon': 6,
            };
            expect(q.options[q.answerIndex].label, '${sides[shape]}');
          }
        }
      }
    });

    test('is deterministic for a seed and varies between seeds', () {
      final a = gen.patterns('l', 5, Random(1)).map((q) => q.id);
      final b = gen.patterns('l', 5, Random(1)).map((q) => q.id);
      final c = gen.patterns('l', 5, Random(2)).map((q) => q.id);
      expect(a.toList(), b.toList());
      expect(a.toList(), isNot(c.toList()));
    });
  });

  group('CatalogAssembler', () {
    const assembler = CatalogAssembler();
    final seed = Catalog([quizSet('mammals', questions: 6)]);
    final now = DateTime(2026, 11, 21, 10);

    GeneratedBank bankWith(int n, {String set = 'mammals'}) {
      var bank = const GeneratedBank();
      for (var i = 0; i < n; i++) {
        bank = bank.add(
          ChoiceQuestion(
            id: 'gen-$set-$i',
            subject: Subject.zoology,
            setId: set,
            prompt: 'Which is $i?',
            options: const [
              AnswerOption(label: 'A'),
              AnswerOption(label: 'B'),
            ],
            answerIndex: 0,
            layout: ChoiceLayout.textList,
          ),
          cap: 100,
        );
      }
      return bank;
    }

    Catalog build(GeneratedBank bank, {int round = 0, int grade = 3}) =>
        assembler.assemble(
          seed: seed,
          bank: bank,
          grade: grade,
          rounds: {'mammals': round},
          now: now,
        );

    test('contains every curriculum set in order with its metadata', () {
      final catalog = build(const GeneratedBank());
      expect(
        catalog.sets.map((s) => s.id),
        Curriculum.blueprints.map((b) => b.id),
      );
      expect(catalog.setById('ocean_life')!.unlockStars, 30);
      expect(catalog.setById('number_fun')!.subject, Subject.numbers);
    });

    test('uses the seed safety net until the model has written enough', () {
      final set = build(bankWith(3)).setById('mammals')!;
      // 3 generated first, then seed questions to pad.
      expect(set.questions.first.id, 'gen-mammals-0');
      expect(set.questions.length, 9);
      expect(set.questions.last.id, startsWith('mammals-'));
    });

    test('uses only generated questions once a full window exists', () {
      final set = build(bankWith(10)).setById('mammals')!;
      expect(set.length, 10);
      expect(set.questions.every((q) => q.id.startsWith('gen-')), isTrue);
    });

    test('each completed round moves to the next window of the bank', () {
      final bank = bankWith(30);
      final ids = [
        for (var round = 0; round < 4; round++)
          build(bank, round: round).setById('mammals')!.questions.first.id,
      ];
      expect(ids, [
        'gen-mammals-0',
        'gen-mammals-10',
        'gen-mammals-20',
        'gen-mammals-0',
      ]);
    });

    test('procedural sets follow the learner grade', () {
      final easy = build(
        const GeneratedBank(),
        grade: 1,
      ).setById('number_fun')!;
      final hard = build(
        const GeneratedBank(),
        grade: 5,
      ).setById('number_fun')!;
      expect(
        easy.questions.map((q) => q.prompt),
        isNot(hard.questions.map((q) => q.prompt)),
      );
      expect(easy.length, 10);
      expect(build(const GeneratedBank()).setById('logic_puzzles')!.length, 9);
    });

    test('is stable within a day and changes the next day', () {
      final today = build(const GeneratedBank()).setById('logic_puzzles')!;
      final again = build(const GeneratedBank()).setById('logic_puzzles')!;
      expect(today, again);
      final tomorrow = assembler.assemble(
        seed: seed,
        bank: const GeneratedBank(),
        grade: 3,
        rounds: const {},
        now: now.add(const Duration(days: 1)),
      );
      expect(
        tomorrow.setById('logic_puzzles')!.questions.map((q) => q.id),
        isNot(today.questions.map((q) => q.id)),
      );
    });
  });
}

/// Thin wrapper so tests read clearly.
class ValidateQuestionProbe {
  const ValidateQuestionProbe();

  bool valid(Question q) => const _V().check(q);
}

class _V {
  const _V();

  bool check(Question q) => const ValidateQuestion()(q) == null;
}

void geometryVarietyTests() {
  test(
    'geometry sets mix drag rounds with picks and counts, without repeats',
    () {
      const gen = ProceduralGenerator();
      for (final grade in [1, 2, 3, 5]) {
        final qs = gen.geometry('g', 10, Random(grade), grade);
        expect(
          qs.whereType<ShapeMatchQuestion>().length,
          2,
          reason: 'grade $grade',
        );
        final prompts = qs
            .whereType<ChoiceQuestion>()
            .map((q) => q.prompt)
            .toList();
        expect(prompts.toSet().length, prompts.length, reason: 'grade $grade');
        expect(qs.length, greaterThanOrEqualTo(9), reason: 'grade $grade');
      }
    },
  );
}
