import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';

/// Illustration for "Learn by playing": tilted animals and a speech bubble.
class PlayArt extends StatelessWidget {
  const PlayArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 24,
          top: 120,
          child: Transform.rotate(
            angle: -0.14,
            child: const ArtView('cat', size: 100),
          ),
        ),
        const Positioned(left: 125, top: 70, child: ArtView('fox', size: 100)),
        Positioned(
          left: 226,
          top: 130,
          child: Transform.rotate(
            angle: 0.14,
            child: const ArtView('rabbit', size: 100),
          ),
        ),
        Positioned(
          left: 84,
          top: 240,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text('Which animal hops?', style: AppText.heading(18)),
          ),
        ),
      ],
    );
  }
}

/// Illustration for "Collect stars": three stars and a progress card.
class StarsArt extends StatelessWidget {
  const StarsArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 45,
          top: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StarIcon(size: 70),
              SizedBox(width: 8),
              StarIcon(size: 110),
              SizedBox(width: 8),
              StarIcon(size: 70),
            ],
          ),
        ),
        Positioned(
          left: 45,
          top: 210,
          width: 260,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stars collected', style: AppText.label(16)),
                Text('26', style: AppText.heading(38)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 12,
                    backgroundColor: AppColors.sand,
                    valueColor: AlwaysStoppedAnimation(AppColors.sunDeep),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Illustration for the parent zone: a sun and a weekly bar chart card.
class GrownUpsArt extends StatelessWidget {
  const GrownUpsArt({super.key});

  static const _bars = [30.0, 50.0, 22.0, 64.0, 44.0, 58.0, 36.0];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(left: 115, top: 40, child: ArtView('sun', size: 120)),
        Positioned(
          left: 45,
          top: 190,
          width: 260,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This week', style: AppText.label(15)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _bars.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Container(
                          width: 22,
                          height: _bars[i],
                          decoration: BoxDecoration(
                            color: AppColors.sunDeep,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('2h 10m of learning', style: AppText.heading(18)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
