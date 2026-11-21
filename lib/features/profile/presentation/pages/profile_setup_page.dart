import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/formatters.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_setup_cubit.dart';
import 'package:wonderly/features/profile/presentation/widgets/buddy_avatar.dart';

/// Create the learner profile, or edit it when one already exists.
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({this.addLearner = false, super.key});

  /// Create another learner instead of editing the active one.
  final bool addLearner;

  @override
  Widget build(BuildContext context) {
    final existing = addLearner
        ? null
        : context.read<ProfileCubit>().state.profile;
    return BlocProvider(
      create: (_) => sl<ProfileSetupCubit>(param1: existing),
      child: _ProfileSetupView(isEditing: existing != null),
    );
  }
}

class _ProfileSetupView extends StatefulWidget {
  const _ProfileSetupView({required this.isEditing});

  final bool isEditing;

  @override
  State<_ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<_ProfileSetupView> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<ProfileSetupCubit>().state.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileSetupCubit, ProfileSetupState>(
      listenWhen: (a, b) => !a.completed && b.completed,
      listener: (context, state) => context.go(Routes.home),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: IntrinsicHeight(
                  child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
                    builder: _buildForm,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProfileSetupState state) {
    final cubit = context.read<ProfileSetupCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Update your buddy' : 'Who is learning?',
          style: AppText.heading(30),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a buddy and tell us your grade.',
          style: AppText.subtitle(17),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final buddy in Buddy.values)
              Semantics(
                button: true,
                selected: buddy == state.buddy,
                label: 'Choose ${buddy.name}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => cubit.selectBuddy(buddy),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: BuddyAvatar(
                      buddy: buddy,
                      size: 58,
                      selected: buddy == state.buddy,
                      background: buddy == state.buddy
                          ? AppColors.butter
                          : AppColors.sand,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Your name', style: AppText.label(15)),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          onChanged: cubit.changeName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: AppConstants.maxNameLength,
          style: AppText.body(20, weight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            errorText: state.errorMessage,
            border: _border(AppColors.ink),
            enabledBorder: _border(AppColors.ink),
            focusedBorder: _border(AppColors.ink),
            errorBorder: _border(AppColors.sunBrown),
            focusedErrorBorder: _border(AppColors.sunBrown),
          ),
        ),
        const SizedBox(height: 18),
        Text('Grade', style: AppText.label(15)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var g = AppConstants.minGrade; g <= AppConstants.maxGrade; g++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _GradeChip(
                  grade: g,
                  selected: g == state.grade,
                  onTap: () => cubit.selectGrade(g),
                ),
              ),
          ],
        ),
        const Spacer(),
        const SizedBox(height: 24),
        WonderButton(
          label: widget.isEditing ? 'Save' : 'Start learning',
          onPressed: state.submitting ? null : cubit.submit,
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(color: color, width: 3),
  );
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  final int grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Grade ${Formatters.ordinal(grade)}',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.ink : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.sand,
            width: 3,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 52,
            child: Center(
              child: Text(
                Formatters.ordinal(grade),
                style: AppText.heading(
                  18,
                  color: selected ? AppColors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
