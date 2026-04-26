import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/coordinator/dashboard_screen.dart';
import 'screens/coordinator/intake_hub_screen.dart';
import 'screens/coordinator/team_manager_screen.dart';
import 'screens/coordinator/assignments_board_screen.dart';
import 'screens/volunteer/volunteer_home_screen.dart';
import 'screens/volunteer/task_detail_screen.dart';

Page<void> _fade(LocalKey key, Widget child) => CustomTransitionPage(
      key: key,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');

    if (state.matchedLocation == '/login' && role == 'coordinator') {
      return '/coordinator/dashboard';
    }
    if (state.matchedLocation == '/login' && role == 'volunteer') {
      return '/volunteer/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login',
        pageBuilder: (c, s) => _fade(s.pageKey, const LoginScreen())),

    // Coordinator
    GoRoute(path: '/coordinator/dashboard',
        pageBuilder: (c, s) => _fade(s.pageKey, const DashboardScreen())),
    GoRoute(path: '/coordinator/intake',
        pageBuilder: (c, s) => _fade(s.pageKey, const IntakeHubScreen())),
    GoRoute(path: '/coordinator/team',
        pageBuilder: (c, s) => _fade(s.pageKey, const TeamManagerScreen())),
    GoRoute(path: '/coordinator/assignments',
        pageBuilder: (c, s) => _fade(s.pageKey, const AssignmentsBoardScreen())),

    // Volunteer
    GoRoute(path: '/volunteer/home',
        pageBuilder: (c, s) => _fade(s.pageKey, const VolunteerHomeScreen())),
    GoRoute(path: '/volunteer/task/:id',
        pageBuilder: (c, s) {
          final id = s.pathParameters['id'] ?? 'T001';
          return _fade(s.pageKey, TaskDetailScreen(taskId: id));
        }),
  ],
);
