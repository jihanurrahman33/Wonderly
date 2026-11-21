import 'package:wonderly/core/storage/key_value_store.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

/// In-memory [KeyValueStore] that can be told to fail writes.
class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;
  bool failWrites = false;

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw const StorageException('disk full');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// [Clock] whose time is set by the test.
class FakeClock implements Clock {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

/// A tiny catalog used across tests.
ChoiceQuestion choiceQuestion(
  String id, {
  String setId = 'set-a',
  Subject subject = Subject.zoology,
  int answerIndex = 1,
}) {
  return ChoiceQuestion(
    id: id,
    subject: subject,
    setId: setId,
    prompt: 'Which one is right?',
    options: const [
      AnswerOption(label: 'A'),
      AnswerOption(label: 'B'),
      AnswerOption(label: 'C'),
    ],
    answerIndex: answerIndex,
    layout: ChoiceLayout.textList,
    fact: 'B is right.',
  );
}

QuizSet quizSet(
  String id, {
  int questions = 3,
  Subject subject = Subject.zoology,
  int? unlockStars,
}) {
  return QuizSet(
    id: id,
    subject: subject,
    title: 'Set $id',
    unlockStars: unlockStars,
    questions: [
      for (var i = 1; i <= questions; i++)
        choiceQuestion('$id-$i', setId: id, subject: subject),
    ],
  );
}
