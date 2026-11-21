import 'package:equatable/equatable.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

/// Who writes the questions of a set.
enum QuestionSource {
  /// The on-device language model, with validation and a second-pass check.
  llm,

  /// Dart code that builds questions whose answers are exactly computable
  /// (maths, shapes, patterns). No model can get these wrong.
  procedural,
}

/// Describes one quiz set. Questions are generated, not hand-written.
class SetBlueprint extends Equatable {
  const SetBlueprint({
    required this.id,
    required this.subject,
    required this.title,
    required this.source,
    this.art,
    this.topic = '',
    this.unlockStars,
    this.quizSize = 10,
  });

  final String id;
  final Subject subject;
  final String title;
  final QuestionSource source;

  /// Illustration key for cards.
  final String? art;

  /// What the model should write about (LLM sets only).
  final String topic;
  final int? unlockStars;

  /// Questions per play of the set.
  final int quizSize;

  /// Questions kept in the on-device bank so each play can differ.
  int get bankTarget => quizSize * 3;

  @override
  List<Object?> get props => [
    id,
    subject,
    title,
    source,
    art,
    topic,
    unlockStars,
    quizSize,
  ];
}

/// The full curriculum.
abstract final class Curriculum {
  static const blueprints = [
    SetBlueprint(
      id: 'mammals',
      subject: Subject.zoology,
      title: 'Mammals',
      art: 'lion',
      source: QuestionSource.llm,
      topic:
          'mammals: what makes an animal a mammal, famous mammals, how '
          'they live, feed their young, and where they live',
    ),
    SetBlueprint(
      id: 'zoology_quiz',
      subject: Subject.zoology,
      title: 'Zoology Quiz',
      art: 'cat',
      source: QuestionSource.llm,
      topic:
          'animals in general: pets, farm animals, wild animals, animal '
          'homes, animal babies, and what animals eat',
    ),
    SetBlueprint(
      id: 'birds',
      subject: Subject.zoology,
      title: 'Birds',
      art: 'owl',
      source: QuestionSource.llm,
      topic: 'birds: feathers, flight, nests, eggs, songs, and famous birds',
    ),
    SetBlueprint(
      id: 'ocean_life',
      subject: Subject.zoology,
      title: 'Ocean life',
      art: 'water_drop',
      source: QuestionSource.llm,
      unlockStars: 30,
      topic:
          'life in the sea: fish, whales, sharks, octopuses, coral, '
          'turtles, and how sea animals breathe and move',
    ),
    SetBlueprint(
      id: 'geometry_shapes',
      subject: Subject.geometry,
      title: 'Geometry shapes',
      art: 'shape_triangle',
      source: QuestionSource.procedural,
    ),
    SetBlueprint(
      id: 'plants_ecosystems',
      subject: Subject.plants,
      title: 'Plant ecosystems',
      art: 'plant_pot',
      source: QuestionSource.llm,
      topic:
          'plants: seeds, roots, stems, leaves, flowers, sunlight, water, '
          'soil, pollination, and how plants help animals and people',
    ),
    SetBlueprint(
      id: 'logic_puzzles',
      subject: Subject.logic,
      title: 'Logic puzzles',
      art: 'shape_star',
      source: QuestionSource.procedural,
      quizSize: 9,
    ),
    SetBlueprint(
      id: 'number_fun',
      subject: Subject.numbers,
      title: 'Number fun',
      art: 'sun',
      source: QuestionSource.procedural,
    ),
    SetBlueprint(
      id: 'word_wizard',
      subject: Subject.words,
      title: 'Word wizard',
      art: 'owl',
      source: QuestionSource.llm,
      topic:
          'words: spelling common words correctly, rhyming words, '
          'opposites, what simple words mean, and the first letter of words',
    ),
  ];

  static SetBlueprint? byId(String id) {
    for (final b in blueprints) {
      if (b.id == id) return b;
    }
    return null;
  }

  static List<SetBlueprint> get llmSets =>
      blueprints.where((b) => b.source == QuestionSource.llm).toList();
}
