import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/core/utils/formatters.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/core/widgets/wonder_switch.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/ai/presentation/a2ui/buddy_agent.dart';
import 'package:wonderly/features/ai/presentation/widgets/buddy_surface.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/learning_stats.dart';
import 'package:wonderly/features/learning/presentation/cubit/catalog_cubit.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/widgets/buddy_avatar.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/domain/services/streak_calculator.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';

/// Parent dashboard: weekly summary, focus areas and play controls.
class GrownUpsPage extends StatelessWidget {
  const GrownUpsPage({super.key});

  void _leave(BuildContext context) {
    sl<ParentAccess>().revoke();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.me);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state.profile;
    final progress = context.watch<ProgressCubit>().state.progress;
    final settings = context.watch<SettingsCubit>().state;
    final catalogState = context.watch<CatalogCubit>().state;
    final catalog = catalogState is CatalogReady ? catalogState.catalog : null;

    final now = DateTime.now();
    final weekSeconds = DayKey.weekOf(now)
        .map((d) => progress.dailySeconds[DayKey.of(d)] ?? 0)
        .fold<int>(0, (a, b) => a + b);
    const goalSeconds = AppConstants.weeklyGoalMinutes * 60;
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WonderBackButton(
                  onPressed: () => _leave(context),
                  label: 'Back to profile',
                ),
                Text('Grown-ups zone', style: AppText.heading(22)),
                Semantics(
                  button: true,
                  label: 'Settings',
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push(Routes.settings),
                      child: const SizedBox.square(
                        dimension: 48,
                        child: Icon(Icons.settings_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile != null)
              _Card(
                child: Row(
                  children: [
                    BuddyAvatar(buddy: profile.buddy, size: 56),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: AppText.heading(18)),
                        Text(
                          '${Formatters.grade(profile.grade)} · '
                          '${StreakCalculator.playedToday(progress.activeDays, now) ? 'Active today' : 'Not played today'}',
                          style: AppText.subtitle(14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (settings.weeklyReport) ...[
              const BuddySurface(kind: BuddyKind.report),
              const SizedBox(height: 14),
            ],
            _WeekCard(seconds: weekSeconds, goalSeconds: goalSeconds),
            const SizedBox(height: 14),
            _SmartBuddyLink(onTap: () => context.push(Routes.smartBuddy)),
            const SizedBox(height: 14),
            const _LearnersCard(),
            const SizedBox(height: 14),
            if (catalog != null)
              _FocusCard(catalog: catalog, progress: progress),
            const SizedBox(height: 14),
            _LimitCard(
              minutes: settings.dailyLimitMinutes,
              onChanged: cubit.setDailyLimit,
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.bedtime_rounded,
                    label: 'Bedtime mode (after 7:30 pm)',
                    value: settings.bedtimeMode,
                    onChanged: (v) => cubit.setBedtimeMode(value: v),
                  ),
                  const Divider(height: 1, color: AppColors.cream),
                  _SwitchRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Weekly note from Smart Buddy',
                    value: settings.weeklyReport,
                    onChanged: (v) => cubit.setWeeklyReport(value: v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            WonderButton(
              label: 'Leave grown-ups zone',
              style: WonderButtonStyle.outlined,
              showIcon: false,
              onPressed: () => _leave(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: child,
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.seconds, required this.goalSeconds});

  final int seconds;
  final int goalSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week', style: AppText.label(15)),
          Text(Formatters.duration(seconds), style: AppText.heading(34)),
          Text(
            'of ${Formatters.duration(goalSeconds)} goal',
            style: AppText.subtitle(16),
          ),
          const SizedBox(height: 10),
          WonderProgressBar(
            value: goalSeconds == 0 ? 0 : seconds / goalSeconds,
            height: 12,
            track: AppColors.sand,
            semanticLabel: 'Weekly goal',
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.catalog, required this.progress});

  final Catalog catalog;
  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final fractions = {
      for (final s in Subject.values)
        s: LearningStats.fractionIn(s, catalog, progress),
    };
    final started = fractions.values.any((f) => f > 0);
    final strong = [
      for (final e in fractions.entries)
        if (e.value >= 0.5) e.key.label,
    ];
    final practise = [
      for (final e in fractions.entries)
        if (e.value < 0.5) e.key.label,
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus areas', style: AppText.heading(19)),
          const SizedBox(height: 10),
          if (!started)
            Text(
              'Focus areas appear once your child has played a quiz.',
              style: AppText.subtitle(15),
            )
          else ...[
            if (strong.isNotEmpty)
              _FocusRow(
                tag: 'Strong',
                color: AppColors.olive,
                textColor: AppColors.white,
                text: strong.join(', '),
              ),
            if (strong.isNotEmpty && practise.isNotEmpty)
              const SizedBox(height: 8),
            if (practise.isNotEmpty)
              _FocusRow(
                tag: 'Practise',
                color: AppColors.sun,
                textColor: AppColors.ink,
                text: practise.join(', '),
              ),
          ],
        ],
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.tag,
    required this.color,
    required this.textColor,
    required this.text,
  });

  final String tag;
  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(tag, style: AppText.label(15, color: textColor)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppText.body(16))),
      ],
    );
  }
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const divisions =
        (AppConstants.maxDailyLimitMinutes -
            AppConstants.minDailyLimitMinutes) ~/
        AppConstants.dailyLimitStepMinutes;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily play limit', style: AppText.heading(19)),
              Text('$minutes min', style: AppText.heading(18)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.sunDeep,
              inactiveTrackColor: AppColors.sand,
              thumbColor: AppColors.ink,
              overlayColor: const Color(0x29171910),
              trackHeight: 10,
            ),
            child: Slider(
              value: minutes.toDouble(),
              min: AppConstants.minDailyLimitMinutes.toDouble(),
              max: AppConstants.maxDailyLimitMinutes.toDouble(),
              divisions: divisions,
              label: '$minutes min',
              semanticFormatterCallback: (v) => '${v.round()} minutes',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.minDailyLimitMinutes} min',
                style: AppText.label(13),
              ),
              Text(
                '${AppConstants.maxDailyLimitMinutes} min',
                style: AppText.label(13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppText.heading(16))),
        WonderSwitch(value: value, onChanged: onChanged, label: label),
      ],
    );
  }
}

class _SmartBuddyLink extends StatelessWidget {
  const _SmartBuddyLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Smart Buddy, on-device AI settings',
      excludeSemantics: true,
      child: Material(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.olive),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Buddy (on-device AI)',
                        style: AppText.heading(17),
                      ),
                      Text(
                        'Model, quiz writing and storage',
                        style: AppText.subtitle(14),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grown-ups can remove a learner (and their progress) here.
class _LearnersCard extends StatelessWidget {
  const _LearnersCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learners on this phone', style: AppText.heading(19)),
          const SizedBox(height: 8),
          for (final learner in state.learners)
            Row(
              children: [
                BuddyAvatar(buddy: learner.buddy, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${learner.name} · ${Formatters.grade(learner.grade)}',
                    style: AppText.body(16),
                  ),
                ),
                if (state.learners.length > 1)
                  IconButton(
                    tooltip: 'Remove ${learner.name}',
                    onPressed: () => _confirm(context, learner),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, LearnerProfile learner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${learner.name}?'),
        content: const Text(
          'Their stars, badges and progress will be erased. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      await context.read<ProfileCubit>().remove(learner.id);
    }
  }
}
