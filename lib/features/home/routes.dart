import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:reptran_app/features/home/presentation/pages/home_page.dart';

class HomeRoutes {
  static const name = 'home';
  static const path = '/home';

  static GoRoute route() => GoRoute(
    name: name,
    path: path,
    // Use a Material motion transition from the `animations` package
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Nice for splash -> next: fade + slight scale-in
        return FadeScaleTransition(animation: animation, child: child);
      },
    ),
  );
}
