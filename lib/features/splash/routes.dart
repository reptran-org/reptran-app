import 'package:go_router/go_router.dart';
import 'presentation/splash_page.dart';

class SplashRoutes {
  static const name = 'splash';
  static const path = '/splash';

  static GoRoute route() => GoRoute(
    name: name,
    path: path,
    pageBuilder: (ctx, state) => const NoTransitionPage(child: SplashPage()),
  );
}
