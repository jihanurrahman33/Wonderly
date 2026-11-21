import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/core/utils/formatters.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/learning_stats.dart';
import 'package:wonderly/features/learning/presentation/widgets/catalog_gate.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Weekly stars, learning time and per-subject progress.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressCubit>().state.progress;
    final now = DateTime.now();
    final week = DayKey.weekOf(now);
    final weekKeys = week.map(DayKey.of).toList();
    final weekStars = [for (final k in weekKeys) progress.dailyStars[k] ?? 0];
    final weekSeconds = weekKeys.fold<int>(
      0,
      (sum, k) => sum + (progress.dailySeconds[k] ?? 0),
    );
    return CatalogGate(
      builder: (context, catalog) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
        children: [
          Row(
            children: [
              WonderBackButton(onPressed: () => context.go(Routes.me)),
              const SizedBox(width: 12),
              Text('My progress', style: AppText.heading(28)),
            ],
          ),
          const SizedBox(height: 14),
          _WeekChart(
            stars: weekStars,
            total: progress.stars,
            todayIndex: now.weekday - 1,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  color: AppColors.cream,
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.sunBrown,
                  value: Formatters.duration(weekSeconds),
                  label: 'Learning time',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  color: AppColors.sage,
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.olive,
                  value: '${progress.correctQuestionIds.length}',
                  label: 'Questions right',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('By subject', style: AppText.heading(19)),
          const SizedBox(height: 10),
          _SubjectBars(catalog: catalog, progress: progress),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.stars,
    required this.total,
    required this.todayIndex,
  });

  final List<int> stars;
  final int total;
  final int todayIndex;

  static const _maxBarHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final peak = stars.fold<int>(1, (m, v) => v > m ? v : m);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stars this week', style: AppText.heading(19)),
              Text('$total total', style: AppText.subtitle(15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < stars.length; i++)
                Expanded(
                  child: Semantics(
                    label: '${_dayNames[i]}: ${stars[i]} stars',
                    excludeSemantics: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${stars[i]}', style: AppText.label(14)),
                        const SizedBox(height: 4),
                        Container(
                          width: 26,
                          height: 6 + _maxBarHeight * stars[i] / peak,
                          decoration: BoxDecoration(
                            color: i == todayIndex
                                ? AppColors.ink
                                : AppColors.sunDeep,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_dayNames[i], style: AppText.label(13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 8),
            Text(value, style: AppText.heading(24)),
            Text(label, style: AppText.subtitle(14)),
          ],
        ),
      ),
    );
  }
}

class _SubjectBars extends StatelessWidget {
  const _SubjectBars({required this.catalog, required this.progress});

  final Catalog catalog;
  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (final subject in Subject.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: _SubjectBar(
                label: subject.label,
                fraction: LearningStats.fractionIn(subject, catalog, progress),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.label, required this.fraction});

  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(16, weight: FontWeight.w800)),
            Text('$percent%', style: AppText.subtitle(15)),
          ],
        ),
        const SizedBox(height: 6),
        WonderProgressBar(
          value: fraction,
          height: 12,
          track: AppColors.sand,
          fill: AppColors.olive,
          semanticLabel: label,
        ),
      ],
    );
  }
}
