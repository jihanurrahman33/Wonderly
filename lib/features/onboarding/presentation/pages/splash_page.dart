import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splash,
      body: SafeArea(
        child: Stack(
          children: [
            const _Dot(left: 30, top: 60, size: 44, color: AppColors.splashDot),
            const _Dot(left: 300, top: 30, size: 26, color: AppColors.white),
            const _Dot(
              right: 10,
              bottom: 200,
              size: 60,
              color: AppColors.splashDot,
            ),
            const _Dot(left: 40, bottom: 180, size: 30, color: AppColors.white),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const ArtView('owl', size: 190),
                  const SizedBox(height: 10),
                  Text(AppConstants.appName, style: AppText.heading(52)),
                  const SizedBox(height: 6),
                  Text(
                    'Learn one question at a time',
                    style: AppText.body(19),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) => WonderButton(
                      label: "Let's go",
                      onPressed: state.status == ProfileStatus.loading
                          ? null
                          : () => context.go(
                              state.hasProfile
                                  ? Routes.home
                                  : Routes.onboarding,
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'For curious kids in grades '
                    '${AppConstants.minGrade} to ${AppConstants.maxGrade}',
                    style: AppText.body(15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.size,
    required this.color,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
