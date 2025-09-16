import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_challenges_page.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_completion_page.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_future_self_page.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_motivation_page.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_progress_preference_page.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_reason_page.dart';
import 'package:reptran_app/features/onboarding/presentation/pages/onboarding_workout_location_page.dart';

class OnboardingRoutes {
  static const path = '/onboarding';

  static GoRoute route() => GoRoute(
    path: path,
    redirect: (context, state) {
      // If already logged in, skip auth flow:
      // return '/home';
      return null;
    },
    routes: [
      GoRoute(
        name: 'reason',
        path: 'reason',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingReasonPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'challenges',
        path: 'challenges',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingChallengesPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'future-self',
        path: 'future-self',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingFutureSelfPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        path: 'workout-location',
        name: 'workout-location',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingWorkoutLocationPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'motivation',
        path: 'motivation',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingMotivationPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        path: 'progress-preference',
        name: 'progress-preference',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingProgressPreferencePage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        path: 'completion',
        name: 'completion',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingCompletionPage(),
          transitionsBuilder: _transition,
        ),
      ),
    ],
  );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondary,
      transitionType: SharedAxisTransitionType.horizontal,
      child: child,
    );
  }
}
