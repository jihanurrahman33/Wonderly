import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wonderly/core/theme/app_colors.dart';

/// Resolves an illustration key (from content or code) to a bundled SVG.
abstract final class AppArt {
  static const _known = {
    'owl',
    'cat',
    'fox',
    'rabbit',
    'lion',
    'shape_circle',
    'shape_triangle',
    'shape_square',
    'shape_star',
    'plant_pot',
    'water_drop',
    'sun',
    'slot_triangle',
    'slot_square',
  };

  static const _shapes = {'circle', 'triangle', 'square', 'star'};

  /// Asset path for [key], or `null` when no illustration exists.
  static String? pathFor(String key) {
    final name = _shapes.contains(key) ? 'shape_$key' : key;
    return _known.contains(name) ? 'assets/svg/$name.svg' : null;
  }
}

/// Shows an illustration by key at [size]; degrades to a soft placeholder.
class ArtView extends StatelessWidget {
  const ArtView(this.artKey, {required this.size, super.key});

  final String artKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = AppArt.pathFor(artKey);
    if (path == null) {
      return SizedBox.square(
        dimension: size,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.sand,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
