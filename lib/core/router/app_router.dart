import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/widgets/app_shell.dart';
import 'package:wonderly/features/ai/presentation/pages/smart_buddy_page.dart';
import 'package:wonderly/features/home/presentation/pages/home_page.dart';
import 'package:wonderly/features/learning/presentation/pages/subject_page.dart';
import 'package:wonderly/features/learning/presentation/pages/subjects_page.dart';
import 'package:wonderly/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:wonderly/features/onboarding/presentation/pages/splash_page.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/parent/presentation/pages/grown_ups_page.dart';
import 'package:wonderly/features/parent/presentation/pages/parent_gate_page.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/pages/profile_page.dart';
import 'package:wonderly/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:wonderly/features/progress/presentation/pages/badge_unlocked_page.dart';
import 'package:wonderly/features/progress/presentation/pages/progress_page.dart';
import 'package:wonderly/features/progress/presentation/pages/rewards_page.dart';
import 'package:wonderly/features/quiz/domain/quiz_summary.dart';
import 'package:wonderly/features/quiz/presentation/pages/quiz_page.dart';
import 'package:wonderly/features/quiz/presentation/pages/results_page.dart';
import 'package:wonderly/features/settings/presentation/pages/settings_page.dart';

/// Rebuilds the router's redirect whenever [stream] emits.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// Builds the app router.
GoRouter buildRouter({
  required ProfileCubit profileCubit,
  required ParentAccess parentAccess,
}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(profileCubit.stream),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final profile = profileCubit.state;
      // Wait for storage before deciding anything.
      if (profile.status == ProfileStatus.loading) {
        return location == Routes.splash ? null : Routes.splash;
      }
      if (!profile.hasProfile && !Routes.publicLocations.contains(location)) {
        return Routes.splash;
      }
      if (Routes.parentOnly.contains(location) && !parentAccess.isActive) {
        return '${Routes.parentGate}?next=${Uri.encodeComponent(location)}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (context, state) => ProfileSetupPage(
          addLearner: state.uri.queryParameters['new'] == '1',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.learn,
                builder: (context, state) => const SubjectsPage(),
                routes: [
                  GoRoute(
                    path: ':${Routes.subjectParam}',
                    builder: (context, state) => SubjectPage(
                      subjectName: state.pathParameters[Routes.subjectParam],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.rewards,
                builder: (context, state) => const RewardsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.me,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'progress',
                    builder: (context, state) => const ProgressPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.quizPattern,
        builder: (context, state) =>
            QuizPage(setId: state.pathParameters[Routes.setParam] ?? ''),
      ),
      GoRoute(
        path: Routes.results,
        redirect: (context, state) =>
            state.extra is QuizSummary ? null : Routes.home,
        builder: (context, state) =>
            ResultsPage(summary: state.extra! as QuizSummary),
      ),
      GoRoute(
        path: Routes.badgePattern,
        builder: (context, state) => BadgeUnlockedPage(
          badgeName: state.pathParameters[Routes.badgeParam],
        ),
      ),
      GoRoute(
        path: Routes.parentGate,
        builder: (context, state) =>
            ParentGatePage(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: Routes.grownUps,
        builder: (context, state) => const GrownUpsPage(),
      ),
      GoRoute(
        path: Routes.smartBuddy,
        builder: (context, state) => const SmartBuddyPage(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
