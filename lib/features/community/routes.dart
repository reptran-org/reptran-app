import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

import 'package:reptran_app/features/community/presentation/pages/community_page.dart';
import 'package:reptran_app/features/community/presentation/pages/community_pulse_page.dart';
import 'package:reptran_app/features/community/presentation/pages/mini_challenge_page.dart';
import 'package:reptran_app/features/community/presentation/pages/notifications_page.dart';
import 'package:reptran_app/features/community/presentation/pages/suggested_users_page.dart';

class CommunityRoutes {
  static const name = 'community';
  static const path = '/community';

  static GoRoute route() => GoRoute(
    name: name,
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const CommunityPage(),
      transitionsBuilder: _transition,
    ),
    routes: [
      GoRoute(
        name: 'miniChallenge',
        path: 'mini-challenge',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MiniChallengePage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'communityPulse',
        path: 'community-pulse',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CommunityPulsePage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'suggestedUsers',
        path: 'suggested-users',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SuggestedBuildersPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'notifications',
        path: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsPage(),
          transitionsBuilder: _transition,
        ),
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
