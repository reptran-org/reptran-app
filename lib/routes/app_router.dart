import 'package:go_router/go_router.dart';
import 'package:reptran_app/features/auth/routes.dart';
import 'package:reptran_app/features/home/routes.dart';
import 'package:reptran_app/features/onboarding/routes.dart';
import '../features/splash/routes.dart';
import '../features/welcome/routes.dart';

final appRouter = GoRouter(
  initialLocation: SplashRoutes.path, // start at Splash
  debugLogDiagnostics: true, // handy during dev
  routes: [
    SplashRoutes.route(),
    WelcomeRoutes.route(),
    AuthRoutes.route(),
    OnboardingRoutes.route(),
    HomeRoutes.route(),
  ],
);
