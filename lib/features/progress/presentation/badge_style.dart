import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';

/// Artwork and colours for each [BadgeId].
extension BadgeStyle on BadgeId {
  Color get color => switch (this) {
    BadgeId.zoologyExplorer => AppColors.amberBadge,
    BadgeId.shapeStarter => AppColors.butter,
    BadgeId.quickThinker => AppColors.mintBadge,
    BadgeId.plantPal => AppColors.sage,
    BadgeId.puzzlePro => AppColors.sky,
    BadgeId.weekWarrior => AppColors.cream,
  };

  /// Badge picture at [size]; shows a lock when [locked].
  Widget art(double size, {bool locked = false}) {
    if (locked) {
      return Icon(Icons.lock_rounded, color: AppColors.muted, size: size * 0.8);
    }
    return switch (this) {
      BadgeId.zoologyExplorer => ArtView('cat', size: size),
      BadgeId.shapeStarter => ArtView('shape_triangle', size: size),
      BadgeId.quickThinker => Icon(
        Icons.bolt_rounded,
        color: AppColors.sunDeep,
        size: size,
      ),
      BadgeId.plantPal => ArtView('plant_pot', size: size),
      BadgeId.puzzlePro => ArtView('shape_star', size: size),
      BadgeId.weekWarrior => Icon(
        Icons.local_fire_department_rounded,
        color: AppColors.sunDeep,
        size: size,
      ),
    };
  }
}
