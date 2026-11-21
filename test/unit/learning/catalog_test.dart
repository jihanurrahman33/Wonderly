import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/features/learning/data/asset_catalog_repository.dart';
import 'package:wonderly/features/learning/data/catalog_parser.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/learning_stats.dart';
import 'package:wonderly/features/learning/domain/usecases/validate_question.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';

import '../../helpers/fakes.dart';

Map<String, Object?> choiceJson({
  String id = 'q',
  List<String> options = const ['A', 'B', 'C'],
  Object? answer = 1,
  String prompt = 'Pick one',
}) => {
  'type': 'choice',
  'id': id,
  'prompt': prompt,
  'options': [
    for (final o in options) {'label': o},
  ],
  'answer': answer,
};

Map<String, Object?> catalogJson(List<Object?> questions) => {
  'sets': [
    {'id': 's', 'subject': 'zoology', 'title': 'S', 'questions': questions},
  ],
};

void main() {
  group('ValidateQuestion', () {
    const validate = ValidateQuestion();
    ChoiceQuestion q({
      List<String> labels = const ['A', 'B', 'C'],
      int answer = 1,
      String prompt = 'Which one?',
    }) => ChoiceQuestion(
      id: 'x',
      subject: Subject.zoology,
      setId: 's',
      prompt: prompt,
      options: [for (final l in labels) AnswerOption(label: l)],
      answerIndex: answer,
    );

    test('accepts a well formed question', () => expect(validate(q()), isNull));

    test('rejects duplicate options', () {
      expect(validate(q(labels: ['A', 'A', 'B'])), 'duplicate options');
    });

    test('rejects out of range answer indexes', () {
      expect(validate(q(answer: 3)), 'answer index out of range');
      expect(validate(q(answer: -1)), 'answer index out of range');
    });

    test('rejects blank options and single option questions', () {
      expect(validate(q(labels: ['A', ' '])), 'blank option');
      expect(validate(q(labels: ['A'])), 'needs at least 2 options');
    });

    test('rejects prompts that are empty or too long', () {
      expect(validate(q(prompt: '  ')), 'empty prompt');
      expect(validate(q(prompt: List.filled(16, 'word').join(' '))), isNotNull);
    });

    test('rejects shape matches with duplicate shapes', () {
      const m = ShapeMatchQuestion(
        id: 'm',
        subject: Subject.geometry,
        setId: 's',
        prompt: 'Match',
        shapes: ['circle', 'circle'],
      );
      expect(validate(m), isNotNull);
    });
  });

  group('CatalogParser', () {
    const parser = CatalogParser();

    test('parses choice, pattern and match questions', () {
      final catalog = parser.parse(
        catalogJson([
          choiceJson(),
          {
            'type': 'pattern',
            'id': 'p',
            'prompt': 'Next?',
            'sequence': ['circle', 'square'],
            'options': ['circle', 'square'],
            'answer': 0,
          },
          {
            'type': 'match',
            'id': 'm',
            'prompt': 'Match',
            'shapes': ['circle', 'square'],
          },
        ]),
      );
      final qs = catalog.sets.single.questions;
      expect(qs[0], isA<ChoiceQuestion>());
      expect(qs[1], isA<PatternQuestion>());
      expect(qs[2], isA<ShapeMatchQuestion>());
    });

    test('skips invalid questions instead of failing the whole bank', () {
      final catalog = parser.parse(
        catalogJson([
          choiceJson(id: 'good'),
          choiceJson(id: 'dup', options: ['A', 'A', 'B']),
          choiceJson(id: 'badAnswer', answer: 'one'),
          {'type': 'mystery', 'id': 'x', 'prompt': 'What?'},
          'not even a map',
        ]),
      );
      expect(catalog.sets.single.questions.map((e) => e.id), ['good']);
    });

    test('skips sets with an unknown subject', () {
      final catalog = parser.parse({
        'sets': [
          {
            'id': 's',
            'subject': 'cooking',
            'title': 'S',
            'questions': <Object?>[],
          },
        ],
      });
      expect(catalog.sets, isEmpty);
    });

    test('throws when sets is missing', () {
      expect(() => parser.parse({}), throwsFormatException);
    });
  });

  group('AssetCatalogRepository', () {
    test('fails with a DataFailure on malformed JSON', () async {
      final repo = AssetCatalogRepository(loadJson: () async => '{oops');
      expect((await repo.load()).failureOrNull, isA<DataFailure>());
    });

    test('fails when every set is empty', () async {
      final repo = AssetCatalogRepository(
        loadJson: () async => jsonEncode(catalogJson([])),
      );
      expect((await repo.load()).failureOrNull, isA<DataFailure>());
    });

    test('caches the parsed catalog after the first load', () async {
      var loads = 0;
      final repo = AssetCatalogRepository(
        loadJson: () async {
          loads++;
          return jsonEncode(catalogJson([choiceJson()]));
        },
      );
      await repo.load();
      await repo.load();
      expect(loads, 1);
    });
  });

  group('bundled question bank', () {
    late Catalog catalog;
    late Map<String, Object?> raw;

    setUpAll(() {
      final text = File('assets/data/questions.json').readAsStringSync();
      raw = jsonDecode(text) as Map<String, Object?>;
      catalog = const CatalogParser().parse(raw);
    });

    test('keeps every authored question (none rejected by validation)', () {
      final authored = (raw['sets']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .fold<int>(
            0,
            (sum, s) => sum + (s['questions']! as List<Object?>).length,
          );
      final parsed = catalog.sets.fold<int>(0, (sum, s) => sum + s.length);
      expect(parsed, authored);
    });

    test('has content for every subject and unique question ids', () {
      for (final subject in Subject.values) {
        expect(
          catalog.questionCountFor(subject),
          greaterThan(0),
          reason: '$subject',
        );
      }
      final ids = [
        for (final s in catalog.sets) ...s.questions.map((q) => q.id),
      ];
      expect(ids.toSet().length, ids.length);
    });

    test('the Zoology Quiz matches the design reference', () {
      final set = catalog.setById('zoology_quiz')!;
      expect(set.length, 10);
      final third = set.questions[2] as ChoiceQuestion;
      expect(third.prompt, 'Which animal is an apex predator?');
      expect(third.options[third.answerIndex].label, 'Lion');
    });

    test('every pattern really repeats to the stated answer', () {
      for (final set in catalog.sets) {
        for (final q in set.questions.whereType<PatternQuestion>()) {
          final seq = q.sequence;
          final answer = q.options[q.answerIndex];
          // Find the shortest period that explains the visible sequence.
          var matched = false;
          for (var period = 1; period < seq.length && !matched; period++) {
            final fits = [
              for (var i = 0; i < seq.length; i++) seq[i] == seq[i % period],
            ].every((e) => e);
            if (fits) matched = seq[seq.length % period] == answer;
          }
          expect(matched, isTrue, reason: q.id);
        }
      }
    });

    test('the locked Ocean life set requires stars', () {
      final ocean = catalog.setById('ocean_life')!;
      expect(ocean.isLocked(29), isTrue);
      expect(ocean.isLocked(30), isFalse);
    });
  });

  group('LearningStats', () {
    final catalog = Catalog([
      quizSet('a', questions: 4),
      quizSet('b', unlockStars: 30),
      quizSet('c', subject: Subject.logic),
    ]);

    test('sums finished questions per subject', () {
      const p = LearnerProgress(setCursor: {'a': 2}, completedSetIds: {'b'});
      expect(LearningStats.doneIn(Subject.zoology, catalog, p), 2 + 3);
      expect(LearningStats.fractionIn(Subject.zoology, catalog, p), 5 / 7);
    });

    test('continueSet prefers a started set', () {
      const p = LearnerProgress(setCursor: {'c': 1});
      expect(LearningStats.continueSet(catalog, p)?.id, 'c');
    });

    test('continueSet skips completed and locked sets', () {
      const p = LearnerProgress(completedSetIds: {'a'});
      expect(LearningStats.continueSet(catalog, p)?.id, 'c');
    });

    test('continueSet falls back to the first playable set when all done', () {
      const p = LearnerProgress(completedSetIds: {'a', 'c'});
      expect(LearningStats.continueSet(catalog, p)?.id, 'a');
    });

    test('continueSet is null when nothing is playable', () {
      expect(
        LearningStats.continueSet(const Catalog([]), const LearnerProgress()),
        isNull,
      );
    });
  });
}
