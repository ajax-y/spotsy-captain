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
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Don't redirect while auth state is loading
      if (authState.isLoading) return null;

      final user = authState.value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';

      if (!isLoggedIn) {
        // Redirect to login if trying to access a protected route
        return isAuthRoute ? null : '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        // Redirect to dashboard if already logged in and trying to access login/register
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(path: '/login', name: 'login',
        builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register',
        builder: (ctx, state) => const RegisterScreen()),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) {
          // Determine current tab index from location
          final loc = state.uri.path;
          int index = 0;
          if (loc.startsWith('/bookings')) {
            index = 1;
          } else if (loc.startsWith('/earnings')) {
            index = 2;
          } else if (loc.startsWith('/profile')) {
            index = 3;
          }

          return MainShell(
            currentIndex: index,
            onTap: (i) {
              switch (i) {
                case 0: ctx.go('/dashboard');
                case 1: ctx.go('/bookings');
                case 2: ctx.go('/earnings');
                case 3: ctx.go('/profile');
              }
            },
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/dashboard', name: 'dashboard',
            builder: (ctx, state) => const DashboardScreen()),
          GoRoute(path: '/bookings', name: 'bookings',
            builder: (ctx, state) => const BookingsScreen()),
          GoRoute(path: '/earnings', name: 'earnings',
            builder: (ctx, state) => const EarningsScreen()),
          GoRoute(path: '/profile', name: 'profile',
            builder: (ctx, state) => const ProfileScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(path: '/parking/add', name: 'parking-add',
        builder: (ctx, state) => const AddEditParkingScreen()),
      GoRoute(path: '/parking/:id', name: 'parking-detail',
        builder: (ctx, state) => ParkingSpaceDetailScreen(spaceId: state.pathParameters['id']!)),
      GoRoute(path: '/parking/:id/edit', name: 'parking-edit',
        builder: (ctx, state) => AddEditParkingScreen(spaceId: state.pathParameters['id']!)),
      GoRoute(path: '/earnings/bank-account', name: 'bank-account',
        builder: (ctx, state) => const BankAccountScreen()),
    ],
  );
});
