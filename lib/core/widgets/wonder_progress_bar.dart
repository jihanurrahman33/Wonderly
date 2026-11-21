import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';

/// Rounded progress bar. [value] is clamped to 0..1.
class WonderProgressBar extends StatelessWidget {
  const WonderProgressBar({
    required this.value,
    this.height = 8,
    this.track = AppColors.trackOnLight,
    this.fill = AppColors.sunDeep,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final double height;
  final Color track;
  final Color fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final safe = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(safe * 100).round()} percent',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: safe,
            minHeight: height,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation(fill),
          ),
        ),
      ),
    );
  }
}
