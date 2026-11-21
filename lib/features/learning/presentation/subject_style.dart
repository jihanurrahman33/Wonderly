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
  };

  String get artKey => switch (this) {
    Subject.zoology => 'cat',
    Subject.geometry => 'shape_triangle',
    Subject.plants => 'plant_pot',
    Subject.logic => 'shape_star',
  };

  String get heroTitle => switch (this) {
    Subject.zoology => 'Meet the animals',
    Subject.geometry => 'Explore shapes',
    Subject.plants => 'Grow with plants',
    Subject.logic => 'Train your brain',
  };

  /// One-line pitch shown on the Home "Keep exploring" cards.
  String get pitch => switch (this) {
    Subject.zoology => 'Meet animals big and small',
    Subject.geometry => 'Learn angles, area and perimeter',
    Subject.plants => 'See how sun, water and soil work together',
    Subject.logic => 'Spot patterns and solve riddles',
  };

  String get cardTitle => switch (this) {
    Subject.zoology => 'Zoology Quiz',
    Subject.geometry => 'Geometry shapes',
    Subject.plants => 'Plant ecosystems',
    Subject.logic => 'Logic puzzles',
  };

  /// Background of the quiz screen for this subject.
  Color get quizColor => switch (this) {
    Subject.zoology => AppColors.sun,
    Subject.geometry => AppColors.cream,
    Subject.plants => AppColors.sage,
    Subject.logic => AppColors.butter,
  };
}
