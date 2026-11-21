import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/usecases/validate_question.dart';

/// Questions the on-device model wrote and that passed every check.
/// Immutable; [add] returns a new bank.
class GeneratedBank extends Equatable {
  const GeneratedBank([this.bySet = const {}]);

  factory GeneratedBank.fromJson(Map<String, Object?> json) {
    final raw = json['sets'];
    final out = <String, List<ChoiceQuestion>>{};
    if (raw is Map<String, Object?>) {
      for (final entry in raw.entries) {
        final list = entry.value;
        if (list is! List<Object?>) continue;
        final questions = <ChoiceQuestion>[
          for (final item in list)
            if (item is Map<String, Object?>) ?_decode(item, entry.key),
        ];
        if (questions.isNotEmpty) out[entry.key] = List.unmodifiable(questions);
      }
    }
    return GeneratedBank(Map.unmodifiable(out));
  }

  final Map<String, List<ChoiceQuestion>> bySet;

  List<ChoiceQuestion> questionsFor(String setId) => bySet[setId] ?? const [];

  int countFor(String setId) => questionsFor(setId).length;

  int get total => bySet.values.fold(0, (sum, l) => sum + l.length);

  Set<String> idsFor(String setId) => {
    for (final q in questionsFor(setId)) q.id,
  };

  /// Adds [question]; when the set is full the oldest question is dropped.
  GeneratedBank add(ChoiceQuestion question, {required int cap}) {
    final current = [...questionsFor(question.setId)];
    if (current.any((q) => q.id == question.id)) return this;
    current.add(question);
    while (current.length > cap) {
      current.removeAt(0);
    }
    return GeneratedBank({
      ...bySet,
      question.setId: List.unmodifiable(current),
    });
  }

  Map<String, Object?> toJson() => {
    'sets': {
      for (final e in bySet.entries)
        e.key: [for (final q in e.value) _encode(q)],
    },
  };

  static Map<String, Object?> _encode(ChoiceQuestion q) => {
    'id': q.id,
    'subject': q.subject.name,
    'prompt': q.prompt,
    'options': [for (final o in q.options) o.label],
    'answer': q.answerIndex,
    'hint': q.hint,
    'fact': q.fact,
  };

  /// Re-validates on load, so corrupt or tampered data can never reach a child.
  static ChoiceQuestion? _decode(Map<String, Object?> json, String setId) {
    final id = json['id'];
    final prompt = json['prompt'];
    final options = json['options'];
    final answer = json['answer'];
    final subject = Subject.tryParse(json['subject'] as String?);
    if (id is! String || prompt is! String || subject == null) return null;
    if (options is! List<Object?> || options.any((o) => o is! String)) {
      return null;
    }
    if (answer is! int) return null;
    final question = ChoiceQuestion(
      id: id,
      subject: subject,
      setId: setId,
      prompt: prompt,
      options: [for (final o in options) AnswerOption(label: o! as String)],
      answerIndex: answer,
      layout: ChoiceLayout.textList,
      hint: json['hint'] as String?,
      fact: json['fact'] as String?,
    );
    return const ValidateQuestion()(question) == null ? question : null;
  }

  @override
  List<Object?> get props => [bySet];
}
