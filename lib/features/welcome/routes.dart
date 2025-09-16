import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'presentation/pages/welcome_page.dart';

class WelcomeRoutes {
  static const name = 'welcome';
  static const path = '/welcome';

  static GoRoute route() => GoRoute(
    name: name,
    path: path,
    // Use a Material motion transition from the `animations` package
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const WelcomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Nice for splash -> next: fade + slight scale-in
        return FadeScaleTransition(animation: animation, child: child);
      },
    ),
  );
}
