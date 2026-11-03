import 'package:go_router/go_router.dart';

import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';
import 'widgets/common.dart';

const _publicPaths = {'/', '/login', '/register'};

GoRouter createRouter(AuthService auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.matchedLocation;
      // Show nothing but a spinner until Firebase knows who is logged in.
      if (auth.initializing) return path == '/loading' ? null : '/loading';
      final loggedIn = auth.user != null;
      if (!loggedIn) {
        return _publicPaths.contains(path) ? null : '/';
      }
      // Stay on the Register screen while it shows "Registration successful".
      if (auth.holdOnRegister) return null;
      // A redirect replaces the whole stack, so Back on the List screen can
      // never return to the Login or Register form.
      if (_publicPaths.contains(path) || path == '/loading') return '/recipes';
      return null;
    },
    routes: [
      GoRoute(path: '/loading', builder: (_, _) => const LoadingScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/recipes',
        builder: (_, _) => const ListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DetailScreen(recipeId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}
