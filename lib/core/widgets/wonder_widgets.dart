import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';

/// Golden star used for rewards.
class StarIcon extends StatelessWidget {
  const StarIcon({this.size = 24, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.star_rounded, color: AppColors.sun, size: size);
}

/// Pill showing the star total; tapping opens Rewards.
class StarsPill extends StatelessWidget {
  const StarsPill({required this.stars, this.onTap, super.key});

  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$stars stars',
      excludeSemantics: true,
      child: Material(
        color: AppColors.cream,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$stars', style: AppText.heading(19)),
                  const SizedBox(width: 6),
                  const StarIcon(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round white back button used in screen headers.
class WonderBackButton extends StatelessWidget {
  const WonderBackButton({
    required this.onPressed,
    this.label = 'Back',
    this.color = AppColors.white,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 48,
            child: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Rounded tinted tile that can be tapped.
class TintedCard extends StatelessWidget {
  const TintedCard({
    required this.color,
    required this.child,
    this.onTap,
    this.radius = 26,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.semanticLabel,
    super.key,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Friendly full-screen message with an optional retry action.
class MessageView extends StatelessWidget {
  const MessageView({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppText.heading(26),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppText.subtitle(17),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: WonderButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  showIcon: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
