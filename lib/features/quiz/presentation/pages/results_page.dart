import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/services/sound_service.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/play_sound_once.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/quiz/domain/quiz_summary.dart';

/// Celebration screen shown when a quiz set is finished.
class ResultsPage extends StatelessWidget {
  const ResultsPage({required this.summary, super.key});

  final QuizSummary summary;

  int get _starRating {
    if (summary.total == 0 || summary.correct == 0) return 0;
    final ratio = summary.correct / summary.total;
    if (ratio >= 0.8) return 3;
    if (ratio >= 0.5) return 2;
    return 1;
  }

  void _continue(BuildContext context) {
    final badge = summary.newBadges.isEmpty ? null : summary.newBadges.first;
    context.go(Routes.home);
    if (badge != null) context.push(Routes.badge(badge.name));
  }

  @override
  Widget build(BuildContext context) {
    final name = context.read<ProfileCubit>().state.profile?.name;
    final hasBadge = summary.newBadges.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.sun,
      body: SafeArea(
        child: Stack(
          children: [
            const _Confetti(),
            const PlaySoundOnce(SoundEffect.complete),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 52,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          color: AppColors.sunDeep,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const ArtView('owl', size: 120),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        name == null ? 'Great job!' : 'Great job, $name!',
                        style: AppText.heading(32),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You finished ${summary.setTitle}',
                        style: AppText.body(17),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _StarRow(filled: _starRating),
                      const SizedBox(height: 20),
                      _StatsCard(summary: summary),
                      const SizedBox(height: 28),
                      WonderButton(
                        label: hasBadge ? 'See my new badge' : 'Back to home',
                        onPressed: () => _continue(context),
                      ),
                      const SizedBox(height: 12),
                      WonderButton(
                        label: 'Review answers',
                        style: WonderButtonStyle.outlined,
                        showIcon: false,
                        onPressed: () => _showReview(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _ReviewSheet(answers: summary.answers),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    const sizes = [64.0, 88.0, 64.0];
    return Semantics(
      label: '$filled out of 3 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              Icons.star_rounded,
              size: sizes[i],
              color: i < filled ? AppColors.white : const Color(0x40FFFFFF),
            ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.summary});

  final QuizSummary summary;

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('${summary.correct}/${summary.total}', 'Correct'),
      (summary.durationLabel, 'Time'),
      ('+${summary.stars}', 'Stars'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  color: AppColors.sand,
                  width: 1,
                  thickness: 2,
                ),
              Expanded(
                child: Semantics(
                  label: '${cells[i].$2}: ${cells[i].$1}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(cells[i].$1, style: AppText.heading(26)),
                      Text(cells[i].$2, style: AppText.subtitle(14)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({required this.answers});

  final List<AnswerRecord> answers;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Text('Your answers', style: AppText.heading(24)),
          const SizedBox(height: 12),
          for (final a in answers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: a.correct ? AppColors.sage : AppColors.butter,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      a.correct
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: a.correct
                          ? AppColors.correct
                          : AppColors.incorrect,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.question.prompt, style: AppText.heading(17)),
                          const SizedBox(height: 4),
                          Text(
                            a.correct
                                ? 'Right: ${a.correctLabel}'
                                : 'You said ${a.chosenLabel ?? 'nothing'}. '
                                      'Answer: ${a.correctLabel}',
                            style: AppText.body(15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti();

  static const _dots = [
    (20.0, 40.0, 18.0, AppColors.cream),
    (300.0, 70.0, 26.0, AppColors.sunDeep),
    (60.0, 300.0, 14.0, AppColors.olive),
    (330.0, 380.0, 20.0, AppColors.cream),
    (30.0, 560.0, 22.0, AppColors.sunDeep),
    (310.0, 600.0, 16.0, AppColors.olive),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        children: [
          for (final (x, y, size, color) in _dots)
            Positioned(
              left: x,
              top: y,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
