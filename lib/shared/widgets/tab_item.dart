// lib/shared/navigation/tab_item.dart
enum TabItem { home, workout, community, profile }

// Optional: keep tab→route mapping here if you like.
// Adjust routes to match your feature roots.
extension TabItemRouteX on TabItem {
  String get route {
    switch (this) {
      case TabItem.home: return '/home';
      case TabItem.workout: return '/workout';
      case TabItem.community: return '/community';
      case TabItem.profile: return '/profile';
    }
  }
}

// Optional helper (if you want to derive selected tab from route):
TabItem tabForRoute(String? route) {
  switch (route) {
    case '/workout': return TabItem.workout;
    case '/community': return TabItem.community;
    case '/profile': return TabItem.profile;
    case '/home':
    default: return TabItem.home;
  }
}
