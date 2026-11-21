import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/formatters.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/widgets/buddy_avatar.dart';
import 'package:wonderly/features/profile/presentation/widgets/learner_switcher_sheet.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

/// "Me" tab: the learner's summary and shortcuts.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state.profile;
    final progressState = context.watch<ProgressCubit>().state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      children: [
        Center(
          child: BuddyAvatar(
            buddy: profile?.buddy ?? _fallbackBuddy,
            size: 120,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile?.name ?? '',
          style: AppText.heading(28),
          textAlign: TextAlign.center,
        ),
        Text(
          profile == null ? '' : Formatters.grade(profile.grade),
          style: AppText.subtitle(17),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Stat(
              color: AppColors.butter,
              icon: const StarIcon(size: 26),
              value: progressState.progress.stars,
              label: 'Stars',
            ),
            const SizedBox(width: 10),
            _Stat(
              color: AppColors.cream,
              icon: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.sunBrown,
                size: 26,
              ),
              value: progressState.progress.badges.length,
              label: 'Badges',
            ),
            const SizedBox(width: 10),
            _Stat(
              color: AppColors.sage,
              icon: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.sunDeep,
                size: 26,
              ),
              value: progressState.streak,
              label: 'Day streak',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _MenuRow(
          icon: Icons.pets_rounded,
          label: 'Change my buddy',
          onTap: () => context.push(Routes.profileSetup),
        ),
        _MenuRow(
          icon: Icons.switch_account_rounded,
          label: 'Switch learner',
          onTap: () => showLearnerSwitcher(context),
        ),
        _MenuRow(
          icon: Icons.insights_rounded,
          label: 'My progress',
          onTap: () => context.push(Routes.progress),
        ),
        _MenuRow(
          icon: Icons.shield_outlined,
          label: 'Grown-ups zone',
          onTap: () => context.push(Routes.grownUps),
        ),
        _MenuRow(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => context.push(Routes.settings),
        ),
      ],
    );
  }
}

const _fallbackBuddy = Buddy.cat;

class _Stat extends StatelessWidget {
  const _Stat({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color color;
  final Widget icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              icon,
              const SizedBox(height: 4),
              Text('$value', style: AppText.heading(24)),
              Text(label, style: AppText.subtitle(14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(width: 14),
                    Expanded(child: Text(label, style: AppText.heading(17))),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
