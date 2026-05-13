import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/bookings/presentation/bookings_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/earnings/presentation/bank_account_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/parking_spaces/presentation/add_edit_parking_screen.dart';
import '../features/parking_spaces/presentation/parking_space_detail_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/presentation/main_shell.dart';

import '../features/auth/data/auth_providers.dart';



final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      
      final user = authState.value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';

      if (!isLoggedIn) return isAuthRoute ? null : '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (ctx, state) => const RegisterScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(index),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (ctx, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bookings', builder: (ctx, state) => const BookingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/earnings', builder: (ctx, state) => const EarningsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (ctx, state) => const ProfileScreen()),
          ]),
        ],
      ),

      GoRoute(path: '/parking/add', builder: (ctx, state) => const AddEditParkingScreen(), parentNavigatorKey: _rootNavigatorKey),
      GoRoute(path: '/parking/:id', builder: (ctx, state) => ParkingSpaceDetailScreen(spaceId: state.pathParameters['id']!), parentNavigatorKey: _rootNavigatorKey),
      GoRoute(path: '/parking/:id/edit', builder: (ctx, state) => AddEditParkingScreen(spaceId: state.pathParameters['id']!), parentNavigatorKey: _rootNavigatorKey),
      GoRoute(path: '/earnings/bank-account', builder: (ctx, state) => const BankAccountScreen(), parentNavigatorKey: _rootNavigatorKey),
    ],
  );
});
