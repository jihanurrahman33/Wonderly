import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/presentation/a2ui/buddy_agent.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/learning_stats.dart';
import 'package:wonderly/features/learning/presentation/cubit/catalog_cubit.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

/// Smart Buddy's card, drawn from A2UI messages written by the on-device agent.
class BuddySurface extends StatefulWidget {
  const BuddySurface({required this.kind, super.key});

  final BuddyKind kind;

  @override
  State<BuddySurface> createState() => _BuddySurfaceState();
}

class _BuddySurfaceState extends State<BuddySurface> {
  late final BuddyAgent _agent = BuddyAgent(
    llm: sl<LlmClient>(),
    canUseModel: () => !sl<GenerationCubit>().state.running,
    onAction: _onAction,
  );
  late final String _surfaceId = 'buddy-${widget.kind.name}';
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final brief = _brief();
    if (brief == null) return;
    await _agent.show(brief, surfaceId: _surfaceId);
    if (mounted) setState(() => _shown = true);
  }

  void _onAction(String name, Map<String, Object?> context) {
    if (name != 'startQuiz' || !mounted) return;
    final setId = context['setId'];
    if (setId is String) unawaited(this.context.push(Routes.quiz(setId)));
  }

  BuddyBrief? _brief() {
    final profile = context.read<ProfileCubit>().state.profile;
    final catalogState = context.read<CatalogCubit>().state;
    if (profile == null || catalogState is! CatalogReady) return null;
    final catalog = catalogState.catalog;
    final progressState = context.read<ProgressCubit>().state;
    final progress = progressState.progress;
    final suggestion = LearningStats.continueSet(catalog, progress);
    if (suggestion == null) return null;

    final fractions = {
      for (final s in Subject.values)
        s: LearningStats.fractionIn(s, catalog, progress),
    };
    final week = DayKey.weekOf(DateTime.now());
    final seconds = week.fold<int>(
      0,
      (sum, d) => sum + (progress.dailySeconds[DayKey.of(d)] ?? 0),
    );
    return BuddyBrief(
      kind: widget.kind,
      name: profile.name,
      grade: profile.grade,
      stars: progress.stars,
      streak: progressState.streak,
      minutesThisWeek: seconds ~/ 60,
      suggestedSetId: suggestion.id,
      suggestedSetTitle: suggestion.title,
      allowedSetIds: {
        for (final QuizSet s in catalog.sets)
          if (!s.isEmpty && !s.isLocked(progress.stars)) s.id,
      },
      strongSubjects: [
        for (final e in fractions.entries)
          if (e.value >= 0.5) e.key.label,
      ],
      practiceSubjects: [
        for (final e in fractions.entries)
          if (e.value < 0.5 && catalog.questionCountFor(e.key) > 0) e.key.label,
      ],
    );
  }

  @override
  void dispose() {
    _agent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.sage,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.olive,
          ),
        ),
      );
    }
    return Surface(surfaceContext: _agent.controller.contextFor(_surfaceId));
  }
}
