import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/formatters.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/widgets/buddy_avatar.dart';

/// Lets children who share a device switch to their own profile or add one.
Future<void> showLearnerSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<ProfileCubit>(),
      child: const _SwitcherBody(),
    ),
  );
}

class _SwitcherBody extends StatelessWidget {
  const _SwitcherBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Who is playing?', style: AppText.heading(24)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final learner in state.learners)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Semantics(
                        button: true,
                        selected: learner.id == state.roster.activeId,
                        label:
                            '${learner.name}, ${Formatters.grade(learner.grade)}',
                        excludeSemantics: true,
                        child: Material(
                          color: learner.id == state.roster.activeId
                              ? AppColors.butter
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () async {
                              await context.read<ProfileCubit>().switchTo(
                                learner.id,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  BuddyAvatar(buddy: learner.buddy, size: 48),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          learner.name,
                                          style: AppText.heading(18),
                                        ),
                                        Text(
                                          Formatters.grade(learner.grade),
                                          style: AppText.subtitle(14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (learner.id == state.roster.activeId)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.olive,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(context.push('${Routes.profileSetup}?new=1'));
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                'Add a learner',
                style: AppText.label(16, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
