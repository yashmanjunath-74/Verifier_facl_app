import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/features/attendance_session/live_session_screen.dart';
import 'package:verifier_facl/features/attendance_session/scan_student_qr_screen.dart';
import 'package:verifier_facl/features/auth/login_screen.dart';
import 'package:verifier_facl/features/auth/onboarding_screen.dart';
import 'package:verifier_facl/features/class_management/class_list_screen.dart';
import 'package:verifier_facl/features/class_management/student_roster_screen.dart';

import '../../main.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isLoggingIn && !isOnboarding) {
        return '/login';
      }

      if (isAuthenticated && (isLoggingIn || isOnboarding)) {
        return '/classes';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/classes',
        builder: (context, state) => const ClassListScreen(),
      ),
      GoRoute(
        path: '/roster/:classId',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return StudentRosterScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/scan/:classId',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return ScanStudentQrScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/session/:classId/:sessionId',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          final sessionId = state.pathParameters['sessionId']!;
          return LiveSessionScreen(classId: classId, sessionId: sessionId);
        },
      ),
    ],
  );
});