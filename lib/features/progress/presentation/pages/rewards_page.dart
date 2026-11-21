import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/features/progress/domain/entities/badge_id.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/services/badge_rules.dart';
import 'package:wonderly/features/progress/presentation/badge_style.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProgressCubit>().state;
    final progress = state.progress;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      children: [
        Text('My rewards', style: AppText.heading(28)),
        const SizedBox(height: 14),
        _StarsCard(stars: progress.stars),
        const SizedBox(height: 14),
        _StreakCard(progress: progress, streak: state.streak),
        const SizedBox(height: 18),
        Text(
          'Badges · ${progress.badges.length} of ${BadgeId.values.length}',
          style: AppText.heading(20),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final badge in BadgeId.values)
              _BadgeTile(badge: badge, earned: progress.badges.contains(badge)),
          ],
        ),
      ],
    );
  }
}

class _StarsCard extends StatelessWidget {
  const _StarsCard({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.starsForPlantPal - stars;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sun,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your stars',
            style: AppText.label(16, color: AppColors.inkSoft),
          ),
          Row(
            children: [
              Text('$stars', style: AppText.heading(46)),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: AppColors.white, size: 40),
            ],
          ),
          Text(
            remaining > 0
                ? '$remaining more stars to unlock Plant Pal'
                : 'You unlocked Plant Pal. Keep collecting!',
            style: AppText.body(15),
          ),
          const SizedBox(height: 10),
          WonderProgressBar(
            value: BadgeRules.plantPalFraction(stars),
            height: 10,
            track: const Color(0x33171910),
            fill: AppColors.ink,
            semanticLabel: 'Progress to Plant Pal',
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.progress, required this.streak});

  final LearnerProgress progress;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final week = DayKey.weekOf(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.sunDeep,
                size: 30,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak == 1 ? '1-day streak' : '$streak-day streak',
                    style: AppText.body(17, weight: FontWeight.w800),
                  ),
                  Text(
                    'Best: ${progress.bestStreak} days',
                    style: AppText.subtitle(14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < week.length; i++)
                _DayDot(
                  letter: _weekdayLetters[i],
                  active: progress.activeDays.contains(DayKey.of(week[i])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.letter, required this.active});

  final String letter;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$letter ${active ? 'played' : 'not played'}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.sunDeep : AppColors.sand,
            ),
          ),
          const SizedBox(height: 4),
          Text(letter, style: AppText.label(13)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earned});

  final BadgeId badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: earned
          ? '${badge.title}, earned'
          : '${badge.title}, locked. ${badge.unlockHint}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (earned) {
            context.push(Routes.badge(badge.name));
          } else {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('${badge.title}: ${badge.unlockHint}')),
              );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: earned ? badge.color : AppColors.lockedBadge,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: badge.art(46, locked: !earned),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.title,
              style: AppText.label(14, color: AppColors.ink),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
