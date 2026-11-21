import 'package:flutter/painting.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';

/// Visual identity for each [Subject].
extension SubjectStyle on Subject {
  Color get color => switch (this) {
    Subject.zoology => AppColors.sage,
    Subject.geometry => AppColors.cream,
    Subject.plants => AppColors.sky,
    Subject.logic => AppColors.butter,
    Subject.numbers => AppColors.cream,
    Subject.words => AppColors.sage,
  };

  String get artKey => switch (this) {
    Subject.zoology => 'cat',
    Subject.geometry => 'shape_triangle',
    Subject.plants => 'plant_pot',
    Subject.logic => 'shape_star',
    Subject.numbers => 'sun',
    Subject.words => 'owl',
  };

  String get heroTitle => switch (this) {
    Subject.zoology => 'Meet the animals',
    Subject.geometry => 'Explore shapes',
    Subject.plants => 'Grow with plants',
    Subject.logic => 'Train your brain',
    Subject.numbers => 'Play with numbers',
    Subject.words => 'Become a word wizard',
  };

  /// One-line pitch shown on the Home "Keep exploring" cards.
  String get pitch => switch (this) {
    Subject.zoology => 'Meet animals big and small',
    Subject.geometry => 'Learn angles, area and perimeter',
    Subject.plants => 'See how sun, water and soil work together',
    Subject.logic => 'Spot patterns and solve riddles',
    Subject.numbers => 'Add, take away, multiply and share',
    Subject.words => 'Spell, rhyme and learn new words',
  };

  String get cardTitle => switch (this) {
    Subject.zoology => 'Zoology Quiz',
    Subject.geometry => 'Geometry shapes',
    Subject.plants => 'Plant ecosystems',
    Subject.logic => 'Logic puzzles',
    Subject.numbers => 'Number fun',
    Subject.words => 'Word wizard',
  };

  /// Background of the quiz screen for this subject.
  Color get quizColor => switch (this) {
    Subject.zoology => AppColors.sun,
    Subject.geometry => AppColors.cream,
    Subject.plants => AppColors.sage,
    Subject.logic => AppColors.butter,
    Subject.numbers => AppColors.sky,
    Subject.words => AppColors.butter,
  };
}
