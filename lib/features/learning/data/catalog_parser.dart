import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/usecases/validate_question.dart';

/// Converts the JSON question bank into domain entities.
///
/// Malformed or invalid questions are skipped (and logged) so one bad entry
/// can never crash the app or reach a child.
class CatalogParser {
  const CatalogParser([this._validate = const ValidateQuestion()]);

  final ValidateQuestion _validate;

  Catalog parse(Map<String, Object?> json) {
    final rawSets = json['sets'];
    if (rawSets is! List<Object?>) {
      throw const FormatException('"sets" must be a list.');
    }
    final sets = <QuizSet>[];
    for (final raw in rawSets) {
      final set = _parseSet(raw);
      if (set != null) sets.add(set);
    }
    return Catalog(List.unmodifiable(sets));
  }

  QuizSet? _parseSet(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final title = raw['title'];
    final subject = Subject.tryParse(raw['subject'] as String?);
    if (id is! String || title is! String || subject == null) {
      AppLogger.warning('Skipping set with missing id, title or subject.');
      return null;
    }
    final questions = <Question>[];
    final rawQuestions = raw['questions'];
    if (rawQuestions is List<Object?>) {
      for (final q in rawQuestions) {
        final question = _parseQuestion(q, subject, id);
        if (question != null) questions.add(question);
      }
    }
    return QuizSet(
      id: id,
      subject: subject,
      title: title,
      art: raw['art'] as String?,
      unlockStars: raw['unlockStars'] as int?,
      questions: List.unmodifiable(questions),
    );
  }

  Question? _parseQuestion(Object? raw, Subject subject, String setId) {
    if (raw is! Map<String, Object?>) return null;
    final question = _build(raw, subject, setId);
    if (question == null) {
      AppLogger.warning('Skipping unreadable question "${raw['id']}".');
      return null;
    }
    final problem = _validate(question);
    if (problem != null) {
      AppLogger.warning('Skipping question "${question.id}": $problem.');
      return null;
    }
    return question;
  }

  Question? _build(Map<String, Object?> raw, Subject subject, String setId) {
    final id = raw['id'];
    final prompt = raw['prompt'];
    if (id is! String || prompt is! String) return null;
    final hint = raw['hint'] as String?;
    final fact = raw['fact'] as String?;
    switch (raw['type']) {
      case 'choice':
        final options = _options(raw['options']);
        final answer = raw['answer'];
        if (options == null || answer is! int) return null;
        return ChoiceQuestion(
          id: id,
          subject: subject,
          setId: setId,
          prompt: prompt,
          options: options,
          answerIndex: answer,
          layout: raw['layout'] == 'list'
              ? ChoiceLayout.textList
              : ChoiceLayout.pictureGrid,
          scene: _strings(raw['scene']),
          hint: hint,
          fact: fact,
        );
      case 'pattern':
        final sequence = _strings(raw['sequence']);
        final options = _strings(raw['options']);
        final answer = raw['answer'];
        if (sequence == null || options == null || answer is! int) return null;
        return PatternQuestion(
          id: id,
          subject: subject,
          setId: setId,
          prompt: prompt,
          sequence: sequence,
          options: options,
          answerIndex: answer,
          hint: hint,
          fact: fact,
        );
      case 'match':
        final shapes = _strings(raw['shapes']);
        if (shapes == null) return null;
        return ShapeMatchQuestion(
          id: id,
          subject: subject,
          setId: setId,
          prompt: prompt,
          shapes: shapes,
          hint: hint,
          fact: fact,
        );
      default:
        return null;
    }
  }

  List<AnswerOption>? _options(Object? raw) {
    if (raw is! List<Object?>) return null;
    final out = <AnswerOption>[];
    for (final o in raw) {
      if (o is! Map<String, Object?> || o['label'] is! String) return null;
      out.add(
        AnswerOption(label: o['label']! as String, art: o['art'] as String?),
      );
    }
    return List.unmodifiable(out);
  }

  List<String>? _strings(Object? raw) {
    if (raw is! List<Object?>) return null;
    if (raw.any((e) => e is! String)) return null;
    return List.unmodifiable(raw.cast<String>());
  }
}
