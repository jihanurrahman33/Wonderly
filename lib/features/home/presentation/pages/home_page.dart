import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/formatters.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/ai/presentation/a2ui/buddy_agent.dart';
import 'package:wonderly/features/ai/presentation/widgets/ai_status_chip.dart';
import 'package:wonderly/features/ai/presentation/widgets/buddy_surface.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/learning_stats.dart';
import 'package:wonderly/features/learning/presentation/subject_style.dart';
import 'package:wonderly/features/learning/presentation/widgets/catalog_gate.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/widgets/buddy_avatar.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogGate(
      builder: (context, catalog) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
        children: [
          const _Header(),
          const SizedBox(height: 14),
          const BuddySurface(kind: BuddyKind.tip),
          const AiStatusChip(),
          const SizedBox(height: 14),
          _ContinueCard(catalog: catalog),
          const SizedBox(height: 14),
          const _StreakCard(),
          const SizedBox(height: 16),
          Text('Keep exploring', style: AppText.heading(21)),
          const SizedBox(height: 12),
          for (final subject in const [
            Subject.geometry,
            Subject.plants,
            Subject.logic,
            Subject.numbers,
            Subject.words,
          ]) ...[
            _ExploreCard(subject: subject, catalog: catalog),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state.profile;
    final stars = context.select((ProgressCubit c) => c.state.progress.stars);
    return Row(
      children: [
        if (profile != null) BuddyAvatar(buddy: profile.buddy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name ?? '',
                style: AppText.body(18, weight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                profile == null ? '' : Formatters.grade(profile.grade),
                style: AppText.subtitle(15),
              ),
            ],
          ),
        ),
        StarsPill(stars: stars, onTap: () => context.go(Routes.rewards)),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressCubit>().state.progress;
    final buddy = context.watch<ProfileCubit>().state.profile?.buddy;
    final set = LearningStats.continueSet(catalog, progress);
    if (set == null) return const SizedBox.shrink();
    final done = progress.doneIn(set.id, set.length);
    final started = done > 0 && done < set.length;
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(30),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -28,
            child: ArtView(buddy?.name ?? 'cat', size: 150),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                set.title,
                style: AppText.heading(28, color: AppColors.white),
              ),
              const SizedBox(height: 6),
              Text(
                started ? 'Keep going!' : 'Ready to play?',
                style: AppText.body(17, color: AppColors.sageSoft),
              ),
              const SizedBox(height: 4),
              Text(
                '$done/${set.length} completed',
                style: AppText.body(15, color: AppColors.sageSoft),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 120,
                child: WonderProgressBar(
                  value: done / set.length,
                  track: AppColors.oliveLight,
                  fill: AppColors.sun,
                  semanticLabel: '${set.title} progress',
                ),
              ),
              const SizedBox(height: 14),
              _PillLink(
                label: started ? 'Continue' : 'Start',
                onTap: () => context.push(Routes.quiz(set.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillLink extends StatelessWidget {
  const _PillLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 46,
            child: Center(child: Text(label, style: AppText.heading(17))),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  static const _daysShown = 7;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProgressCubit>().state;
    final streak = state.streak;
    final filled = streak.clamp(0, _daysShown);
    final subtitle = streak == 0
        ? 'Play today to start a streak'
        : state.playedToday
        ? 'You played today. Great job!'
        : 'Play today to keep it going';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.sunDeep,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 1 ? '1-day streak' : '$streak-day streak',
                  style: AppText.body(17, weight: FontWeight.w800),
                ),
                Text(subtitle, style: AppText.subtitle(14)),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < _daysShown; i++)
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < filled ? AppColors.sunDeep : AppColors.sand,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.subject, required this.catalog});

  final Subject subject;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      color: subject.color,
      semanticLabel: subject.cardTitle,
      onTap: () {
        final sets = catalog.setsFor(subject);
        context.push(
          sets.length == 1
              ? Routes.quiz(sets.first.id)
              : Routes.subject(subject.name),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.cardTitle, style: AppText.heading(20)),
                  const SizedBox(height: 4),
                  Text(subject.pitch, style: AppText.subtitle(14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ArtView(subject.artKey, size: 56),
          ],
        ),
      ),
    );
  }
}
