import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';

enum WonderButtonStyle { dark, light, outlined }

/// Large pill button used for primary actions.
class WonderButton extends StatelessWidget {
  const WonderButton({
    required this.label,
    required this.onPressed,
    this.style = WonderButtonStyle.dark,
    this.icon = Icons.arrow_forward_rounded,
    this.showIcon = true,
    this.height = 58,
    super.key,
  });

  final String label;

  /// `null` renders the disabled state.
  final VoidCallback? onPressed;
  final WonderButtonStyle style;
  final IconData icon;
  final bool showIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (bg, fg, border) = switch (style) {
      WonderButtonStyle.dark => (
        enabled ? AppColors.ink : AppColors.trackOnLight,
        enabled ? AppColors.white : AppColors.inkSoft,
        Colors.transparent,
      ),
      WonderButtonStyle.light => (
        AppColors.background,
        AppColors.ink,
        Colors.transparent,
      ),
      WonderButtonStyle.outlined => (
        AppColors.white,
        AppColors.ink,
        AppColors.ink,
      ),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border, width: 3)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppText.heading(19, color: fg)),
                if (showIcon) ...[
                  const SizedBox(width: 10),
                  Icon(icon, color: fg, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
