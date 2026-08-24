import 'package:go_router/go_router.dart';

import 'package:reptran_app/features/notifications/services/nudge_intent_handler.dart';

import 'package:reptran_app/features/auth/routes.dart';
import 'package:reptran_app/features/home/routes.dart';
import 'package:reptran_app/features/onboarding/routes.dart';
import 'package:reptran_app/features/profile/routes.dart';
import 'package:reptran_app/features/workout/routes.dart';
import 'package:reptran_app/features/community/routes.dart';
import '../features/splash/routes.dart';
import '../features/welcome/routes.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: NudgeIntentHandler.navigatorKey, // ✅ REQUIRED
  initialLocation: SplashRoutes.path,
  debugLogDiagnostics: true,
  routes: [
    SplashRoutes.route(),
    WelcomeRoutes.route(),
    AuthRoutes.route(),
    OnboardingRoutes.route(),
    HomeRoutes.route(),
    WorkoutRoutes.route(),
    CommunityRoutes.route(),
    ProfileRoutes.route(),
  ],
);
