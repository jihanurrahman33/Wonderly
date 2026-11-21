import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';

const _cheers = [
  'Great job!',
  'Brilliant!',
  'You got it!',
  'Super!',
  'Well done!',
];

/// Feedback card shown after an answer is checked.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    required this.correct,
    required this.questionNumber,
    required this.starsGained,
    this.fact,
    super.key,
  });

  final bool correct;
  final int questionNumber;
  final int starsGained;
  final String? fact;

  @override
  Widget build(BuildContext context) {
    final accent = correct ? AppColors.correct : AppColors.incorrect;
    final title = correct
        ? '${_cheers[questionNumber % _cheers.length]} That is right'
        : 'Good try! Almost there';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: correct ? AppColors.sage : AppColors.butter,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    correct ? Icons.check_rounded : Icons.close_rounded,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: AppText.heading(22))),
              ],
            ),
            if (fact != null) ...[
              const SizedBox(height: 8),
              Text(fact!, style: AppText.body(16, weight: FontWeight.w700)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (correct && starsGained > 0) ...[
                  const StarIcon(size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '+$starsGained ${starsGained == 1 ? 'star' : 'stars'}',
                    style: AppText.body(16, weight: FontWeight.w800),
                  ),
                ] else
                  Text(
                    correct ? 'Already collected' : 'Every try helps you learn',
                    style: AppText.body(15, color: AppColors.inkSoft),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
