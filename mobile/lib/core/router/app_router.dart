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

final routerProvider = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onSplash = state.matchedLocation == '/';
      final onAuth = state.matchedLocation == '/auth';

      if (onSplash) return null;

      if (!isAuth && !onAuth) return '/auth';
      if (isAuth && onAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/add', builder: (_, __) => const AddExpenseScreen()),
      GoRoute(
        path: '/categories',
        builder: (_, state) => CategoryPickerScreen(
          pickerMode: state.extra == true,
        ),
      ),
      GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
