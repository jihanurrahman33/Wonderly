import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';
import 'package:wonderly/features/progress/presentation/badge_style.dart';

/// Celebration for a badge the child earned.
class BadgeUnlockedPage extends StatelessWidget {
  const BadgeUnlockedPage({required this.badgeName, super.key});

  final String? badgeName;

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = BadgeId.tryParse(badgeName);
    if (badge == null) {
      return Scaffold(
        body: MessageView(
          title: 'Hmm, not found',
          message: 'We could not find that badge.',
          actionLabel: 'Back',
          onAction: () => _close(context),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.sun,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('New badge!', style: AppText.heading(18)),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: '${badge.title} badge',
                excludeSemantics: true,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: badge.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: badge.art(110),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                badge.title,
                style: AppText.heading(34),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                badge.celebration,
                style: AppText.body(18, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StarIcon(size: 26),
                    const SizedBox(width: 8),
                    Text(
                      '+${AppConstants.starsPerBadge} bonus stars',
                      style: AppText.heading(18),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              WonderButton(label: 'Collect', onPressed: () => _close(context)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(Routes.home),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(
                  'Back to home',
                  style: AppText.label(17, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
