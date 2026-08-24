import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:reptran_app/features/profile/presentation/pages/appearance_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/badges_showcase_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/email_password.dart';
import 'package:reptran_app/features/profile/presentation/pages/environment_summary_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/followers_following_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/help_and_about_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/privacy_data_page.dart';

import 'package:reptran_app/features/profile/presentation/pages/profile_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/identity_edit_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/identity_check_in_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/public_profile_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/recovery_completion_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/recovery_flow_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/reonboarding_flow_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/settings_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/trigger_settings_page.dart';
import 'package:reptran_app/features/profile/presentation/pages/notification_settings_page.dart';

class ProfileRoutes {
  static const String path = '/profile';

  /// Parent route renders the ProfilePage for "/profile"
  static GoRoute route() => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const ProfilePage(), // <-- parent handles "/profile"
      transitionsBuilder: _transition,
    ),
    routes: [
      // /profile/edit -> IdentityEditPage
      GoRoute(
        name: 'profileEdit',
        path: 'edit',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const IdentityPage(),
          transitionsBuilder: _transition,
        ),
      ),

      GoRoute(
        path: 'edit-profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfilePage(), // ✅ no user needed
          transitionsBuilder: _transition,
        ),
      ),

      GoRoute(
        path: 'appearance',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AppearanceScreen(),
          transitionsBuilder: _transition,
        ),
      ),

      GoRoute(
        name: 'privacyAndData',
        path: 'privacy-and-data',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: PrivacyDataPage(),
            transitionsBuilder: _transition,
          );
        },
      ),
      GoRoute(
        name: 'notificationsSetting',
        path: 'notifications',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: NotificationsSettingsPage(),
            transitionsBuilder: _transition,
          );
        },
      ),

      GoRoute(
        path: 'email-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmailPasswordPage(),
          transitionsBuilder: _transition,
        ),
      ),
      // /profile/identity-check-in -> IdentityCheckInPage
      GoRoute(
        name: 'identityCheckIn',
        path: 'identity-check-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const IdentityCheckInPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'triggerSettings',
        path: 'settings/environment',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TriggerSettingsPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'badgeShowcase',
        path: 'badge-showcase',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BadgesShowcasePage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'reonboardingFlow',
        path: 'reonboarding-flow',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ComebackFlowPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'recoveryFlow',
        path: 'recovery-flow',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RecoverFlowPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'recoveryCompletion',
        path: 'recovery-completion',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RecoverCompletionPage(),
          transitionsBuilder: _transition,
        ),
      ),

      GoRoute(
        name: 'followersFollowing',
        path: 'followers-following',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FollowersFollowingPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'environmentSummary',
        path: 'environment-summary',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EnvironmentSummaryPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'publicProfile',
        path: ':username',
        pageBuilder: (context, state) {
          final username = state.pathParameters['username']!;

          return CustomTransitionPage(
            key: state.pageKey,
            child: PublicProfilePage(username: username),
            transitionsBuilder: _transition,
          );
        },
      ),
      GoRoute(
        name: 'settings',
        path: 'settings/account',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'helpAndAbout',
        path: 'settings/help-and-about',
        pageBuilder: (context, state) {
          final target = state.extra as String?;

          return CustomTransitionPage(
            key: state.pageKey,
            child: HelpAndAboutPage(
              targetSection: target, // 👈 pass section
            ),
            transitionsBuilder: _transition,
          );
        },
      ),
    ],
  );

  static List<GoRoute> routes() => [route()];

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) => FadeScaleTransition(animation: animation, child: child);
}
