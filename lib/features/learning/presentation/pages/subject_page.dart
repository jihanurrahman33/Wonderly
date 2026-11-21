import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/presentation/subject_style.dart';
import 'package:wonderly/features/learning/presentation/widgets/catalog_gate.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

/// Lists the quiz sets of one subject, for example Zoology.
class SubjectPage extends StatelessWidget {
  const SubjectPage({required this.subjectName, super.key});

  final String? subjectName;

  @override
  Widget build(BuildContext context) {
    final subject = Subject.tryParse(subjectName);
    if (subject == null) {
      return MessageView(
        title: 'Hmm, not found',
        message: 'We could not find that subject.',
        actionLabel: 'Back to subjects',
        onAction: () => context.go(Routes.learn),
      );
    }
    return CatalogGate(
      builder: (context, catalog) {
        final progress = context.watch<ProgressCubit>().state.progress;
        final sets = catalog.setsFor(subject);
        final questions = catalog.questionCountFor(subject);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WonderBackButton(onPressed: () => context.go(Routes.learn)),
                Text(subject.label, style: AppText.heading(24)),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 14),
            _Hero(
              subject: subject,
              subtitle: '${sets.length} quiz sets · $questions questions',
            ),
            const SizedBox(height: 14),
            Text('Quiz sets', style: AppText.heading(21)),
            const SizedBox(height: 12),
            for (final set in sets) ...[
              _SetTile(set: set, progress: progress),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.subject, required this.subtitle});

  final Subject subject;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -26,
            child: ArtView(subject.artKey, size: 100),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.heroTitle,
                style: AppText.heading(22, color: AppColors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppText.body(15, color: AppColors.sageSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({required this.set, required this.progress});

  final QuizSet set;
  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final locked = set.isLocked(progress.stars);
    final done = progress.doneIn(set.id, set.length);
    final complete = progress.completedSetIds.contains(set.id);
    final inProgress = !complete && done > 0;

    final subtitle = locked
        ? 'Earn ${set.unlockStars} stars to open'
        : complete
        ? '${set.length} of ${set.length} done'
        : inProgress
        ? '$done of ${set.length} done'
        : '${set.length} new questions';

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Semantics(
        button: !locked,
        label: '${set.title}. $subtitle',
        excludeSemantics: true,
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: inProgress ? AppColors.sun : Colors.transparent,
              width: 3,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: locked || set.isEmpty
                ? null
                : () => context.push(Routes.quiz(set.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: ArtView(set.art ?? set.subject.artKey, size: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(set.title, style: AppText.heading(18)),
                        Text(subtitle, style: AppText.subtitle(14)),
                      ],
                    ),
                  ),
                  _Trailing(
                    locked: locked,
                    complete: complete,
                    inProgress: inProgress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.locked,
    required this.complete,
    required this.inProgress,
  });

  final bool locked;
  final bool complete;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return const Icon(Icons.lock_rounded, color: AppColors.muted);
    }
    if (complete) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [StarIcon(size: 22), StarIcon(size: 22), StarIcon(size: 22)],
      );
    }
    return _Chip(
      label: inProgress ? 'Continue' : 'Start',
      background: inProgress ? AppColors.sun : AppColors.ink,
      foreground: inProgress ? AppColors.ink : AppColors.white,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label, style: AppText.label(15, color: foreground)),
    );
  }
}
