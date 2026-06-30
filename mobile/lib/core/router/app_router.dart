import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_expense/add_expense_screen.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/categories/category_picker_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/folio_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Keeps one [GoRouter] instance — recreating it remounts the shell and crashes PageView.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen<bool>(isAuthenticatedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isAuth = ref.read(isAuthenticatedProvider);
      final onSplash = state.matchedLocation == '/';
      final onAuth = state.matchedLocation == '/auth';

      if (onSplash) return null;
      if (!isAuth && !onAuth) return '/auth';
      if (isAuth && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return FolioShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return FolioPager(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, _) => const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                pageBuilder: (_, _) => const NoTransitionPage(child: CategoryPickerScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                pageBuilder: (_, _) => const NoTransitionPage(child: InsightsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (_, _) => const NoTransitionPage(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/add',
        builder: (_, _) => const AddExpenseScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/pick-category',
        builder: (_, _) => const CategoryPickerScreen(pickerMode: true),
      ),
    ],
  );
});
