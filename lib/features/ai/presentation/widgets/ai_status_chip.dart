import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/ai/presentation/cubit/model_cubit.dart';

/// Tells a child what Smart Buddy is doing, in kid-friendly words.
///
/// While the model is writing quizzes it shows progress. If the model has not
/// been set up, it invites the child to ask a grown-up (the tap goes through
/// the parent gate).
class AiStatusChip extends StatelessWidget {
  const AiStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ModelCubit>().state;
    final generation = context.watch<GenerationCubit>().state;

    if (generation.running) {
      return _Chip(
        icon: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.olive,
          ),
        ),
        text:
            'Smart Buddy is writing new quizzes '
            '(${generation.made}/${generation.wanted})',
        color: AppColors.sage,
      );
    }
    if (model.status is ModelNotInstalled) {
      return _Chip(
        icon: const Icon(
          Icons.bedtime_rounded,
          size: 20,
          color: AppColors.sunBrown,
        ),
        text: 'Smart Buddy is sleeping. Ask a grown-up to wake it up.',
        color: AppColors.butter,
        onTap: () => context.push(Routes.smartBuddy),
      );
    }
    if (model.status is ModelDownloading) {
      final percent = (model.status as ModelDownloading).percent;
      return _Chip(
        icon: const Icon(
          Icons.downloading_rounded,
          size: 20,
          color: AppColors.olive,
        ),
        text: 'Smart Buddy is waking up ($percent%)',
        color: AppColors.sage,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  final Widget icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        button: onTap != null,
        label: text,
        excludeSemantics: true,
        liveRegion: true,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: AppText.body(14))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
