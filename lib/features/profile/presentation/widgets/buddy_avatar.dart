import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';

/// Round avatar showing a [Buddy] on a soft background.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({
    required this.buddy,
    this.size = 50,
    this.background = AppColors.butter,
    this.selected = false,
    super.key,
  });

  final Buddy buddy;
  final double size;
  final Color background;

  /// Draws the dark selection ring used on the profile setup screen.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: selected
            ? const [BoxShadow(color: AppColors.ink, spreadRadius: 4)]
            : null,
      ),
      child: ArtView(buddy.name, size: size * 0.8),
    );
  }
}
