import 'dart:math';

import 'package:wonderly/core/utils/stable_hash.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

/// Builds questions whose answers are exactly computable, so they are always
/// correct: shape patterns, shape facts and arithmetic.
///
/// Output is deterministic for a given [Random] seed.
class ProceduralGenerator {
  const ProceduralGenerator();

  static const _shapes = ['circle', 'square', 'triangle', 'star'];
  static const _templates = ['AB', 'AAB', 'ABB', 'ABC'];

  /// Pattern-completion questions ("What comes next?").
  List<PatternQuestion> patterns(String setId, int count, Random random) {
    final seen = <String>{};
    final out = <PatternQuestion>[];
    var guard = 0;
    while (out.length < count && guard++ < count * 40) {
      final template = _templates[random.nextInt(_templates.length)];
      final shapes = [..._shapes]..shuffle(random);
      final unit = [
        for (final c in template.split('')) shapes[c.codeUnitAt(0) - 65],
      ];
      final extra = random.nextInt(unit.length);
      final length = min(8, unit.length * 2 + extra);
      final sequence = [for (var i = 0; i < length; i++) unit[i % unit.length]];
      final answer = unit[length % unit.length];
      final key = '${sequence.join(',')}>$answer';
      if (!seen.add(key)) continue;
      final others =
          (_shapes.where((s) => s != answer).toList()..shuffle(random)).take(2);
      final options = [answer, ...others]..shuffle(random);
      out.add(
        PatternQuestion(
          id: 'logic-${StableHash.of(key)}',
          subject: Subject.logic,
          setId: setId,
          prompt: 'What comes next?',
          sequence: sequence,
          options: options,
          answerIndex: options.indexOf(answer),
          hint: 'Look at the order. It repeats.',
          fact: 'The pattern repeats, so $answer comes next.',
        ),
      );
    }
    return out;
  }

  static const _picks = [
    (
      'Which shape has no corners?',
      'circle',
      'A circle is round, so it has no corners.',
    ),
    (
      'Which shape is perfectly round?',
      'circle',
      'A circle is perfectly round.',
    ),
    (
      'Which shape has three sides?',
      'triangle',
      'A triangle has 3 sides and 3 corners.',
    ),
    (
      'Which shape has three corners?',
      'triangle',
      'A triangle has 3 sides and 3 corners.',
    ),
    (
      'Which shape has four equal sides?',
      'square',
      'Every side of a square is the same length.',
    ),
    (
      'Which shape has four corners?',
      'square',
      'A square has 4 sides and 4 corners.',
    ),
  ];

  static const _sides = {
    'triangle': 3,
    'square': 4,
    'pentagon': 5,
    'hexagon': 6,
  };

  /// Shape questions: two drag-and-match rounds plus picking and counting
  /// shapes. Every prompt appears at most once.
  List<Question> geometry(String setId, int count, Random random, int grade) {
    final pool = <Question>[
      for (final (prompt, answer, fact) in _picks)
        _pick(setId, prompt, answer, fact, random),
      for (final entry in _sides.entries)
        if (grade >= 3 || entry.value <= 4)
          for (final corners in [true, false])
            _numberChoice(
              setId,
              corners
                  ? 'How many corners does a ${entry.key} have?'
                  : 'How many sides does a ${entry.key} have?',
              entry.value,
              random,
              corners ? 'geo-corners' : 'geo-sides',
              'A ${entry.key} has ${entry.value} sides and ${entry.value} corners.',
              'Count them one by one.',
              min: 2,
              max: 8,
            ),
    ]..shuffle(random);

    final matches = <Question>[
      for (var i = 0; i < 2 && i < count; i++) _match(setId, random),
    ];
    final rest = pool.take(max(0, count - matches.length)).toList();
    final out = [...rest];
    if (matches.isNotEmpty) out.insert(0, matches[0]);
    if (matches.length > 1) {
      out.insert(min(out.length, count ~/ 2 + 1), matches[1]);
    }
    return out;
  }

  ShapeMatchQuestion _match(String setId, Random random) {
    final shapes = ([..._shapes]..shuffle(random)).take(3).toList();
    return ShapeMatchQuestion(
      id: 'geo-match-${StableHash.of('${shapes.join(',')}-${random.nextInt(1 << 30)}')}',
      subject: Subject.geometry,
      setId: setId,
      prompt: 'Drag each shape to its match',
      shapes: shapes,
      hint: 'Look at the outline.',
      fact: 'Shapes can be matched by their outlines.',
    );
  }

  ChoiceQuestion _pick(
    String setId,
    String prompt,
    String answer,
    String fact,
    Random random,
  ) {
    final options = [..._shapes]..shuffle(random);
    return ChoiceQuestion(
      id: 'geo-pick-${StableHash.of('$prompt-${options.join()}')}',
      subject: Subject.geometry,
      setId: setId,
      prompt: prompt,
      options: [
        for (final s in options)
          AnswerOption(label: _title(s), art: 'shape_$s'),
      ],
      answerIndex: options.indexOf(answer),
      hint: 'Picture each shape in your head.',
      fact: fact,
    );
  }

  ChoiceQuestion _numberChoice(
    String setId,
    String prompt,
    int answer,
    Random random,
    String idPrefix,
    String fact,
    String hint, {
    required int min,
    required int max,
  }) {
    final pool = [
      for (var i = min; i <= max; i++)
        if (i != answer) i,
    ]..shuffle(random);
    final values = [answer, ...pool.take(3)]..shuffle(random);
    return ChoiceQuestion(
      id: '$idPrefix-${StableHash.of('$prompt-${values.join()}')}',
      subject: Subject.geometry,
      setId: setId,
      prompt: prompt,
      options: [for (final v in values) AnswerOption(label: '$v')],
      answerIndex: values.indexOf(answer),
      layout: ChoiceLayout.textList,
      hint: hint,
      fact: fact,
    );
  }

  /// Arithmetic questions whose difficulty follows the learner's [grade].
  List<ChoiceQuestion> numbers(
    String setId,
    int count,
    Random random,
    int grade,
  ) {
    final seen = <String>{};
    final out = <ChoiceQuestion>[];
    var guard = 0;
    while (out.length < count && guard++ < count * 60) {
      final q = _arithmetic(setId, random, grade.clamp(1, 5));
      if (q != null && seen.add(q.prompt)) out.add(q);
    }
    return out;
  }

  ChoiceQuestion? _arithmetic(String setId, Random random, int grade) {
    String prompt;
    int answer;
    String hint;
    switch (_operationFor(random, grade)) {
      case _Op.add:
        final max = switch (grade) {
          1 => 10,
          2 => 20,
          3 => 100,
          4 => 1000,
          _ => 5000,
        };
        final a = 1 + random.nextInt(max);
        final b = 1 + random.nextInt(max);
        prompt = '$a + $b = ?';
        answer = a + b;
        hint = 'Add the ones first, then the tens.';
      case _Op.subtract:
        final max = switch (grade) {
          1 => 10,
          2 => 20,
          3 => 100,
          4 => 1000,
          _ => 5000,
        };
        final a = 2 + random.nextInt(max - 1);
        final b = 1 + random.nextInt(a - 1);
        prompt = '$a − $b = ?';
        answer = a - b;
        hint = 'Count back from the bigger number.';
      case _Op.multiply:
        final maxA = switch (grade) {
          3 => 5,
          4 => 10,
          _ => 12,
        };
        final a = 2 + random.nextInt(maxA - 1);
        final b = 2 + random.nextInt(maxA - 1);
        prompt = '$a × $b = ?';
        answer = a * b;
        hint = 'Think of $a groups of $b.';
      case _Op.divide:
        final b = 2 + random.nextInt(grade >= 5 ? 11 : 9);
        final result = 2 + random.nextInt(grade >= 5 ? 11 : 9);
        prompt = '${b * result} ÷ $b = ?';
        answer = result;
        hint = 'How many $b s fit into ${b * result}?';
    }
    final distractors = <int>{};
    final deltas = [1, -1, 2, -2, 10, -10, 5, -5];
    while (distractors.length < 3) {
      final d =
          answer +
          deltas[random.nextInt(deltas.length)] * (1 + random.nextInt(2));
      if (d > 0 && d != answer) distractors.add(d);
    }
    final values = [answer, ...distractors]..shuffle(random);
    return ChoiceQuestion(
      id: 'num-${StableHash.of('$prompt-${values.join(',')}')}',
      subject: Subject.numbers,
      setId: setId,
      prompt: prompt,
      options: [for (final v in values) AnswerOption(label: '$v')],
      answerIndex: values.indexOf(answer),
      hint: hint,
      fact: '${prompt.replaceAll('?', '$answer')}.',
    );
  }

  _Op _operationFor(Random random, int grade) {
    final ops = switch (grade) {
      1 || 2 => [_Op.add, _Op.subtract],
      3 => [_Op.add, _Op.subtract, _Op.multiply],
      _ => [_Op.add, _Op.subtract, _Op.multiply, _Op.divide],
    };
    return ops[random.nextInt(ops.length)];
  }

  String _title(String s) => '${s[0].toUpperCase()}${s.substring(1)}';
}

enum _Op { add, subtract, multiply, divide }
