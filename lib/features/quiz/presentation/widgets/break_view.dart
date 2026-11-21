import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/features/settings/domain/services/play_guard.dart';

/// Shown when the daily limit or bedtime ends play.
class BreakView extends StatelessWidget {
  const BreakView({required this.reason, required this.onHome, super.key});

  final BreakReason reason;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (reason) {
      BreakReason.dailyLimit => (
        'Time for a break!',
        'You have played enough for today. Your buddy will be here '
            'tomorrow.',
      ),
      BreakReason.bedtime => (
        'Sweet dreams!',
        'It is bedtime, so Wonderly is resting. See you in the morning.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        children: [
          const Spacer(),
          const ArtView('owl', size: 160),
          const SizedBox(height: 20),
          Text(title, style: AppText.heading(32), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppText.body(17, color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          WonderButton(label: 'Back to home', onPressed: onHome),
        ],
      ),
    );
  }
}
