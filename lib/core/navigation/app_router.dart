import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/features/auth/login_screen.dart';
import 'package:verifier_facl/features/auth/onboarding_screen.dart';
import 'package:verifier_facl/features/class_management/class_list_screen.dart';
import 'package:verifier_facl/features/class_management/create_class_screen.dart';
import 'package:verifier_facl/features/class_management/student_roster_screen.dart';
import 'package:verifier_facl/features/attendance_session/scan_student_qr_screen.dart';
import 'package:verifier_facl/features/attendance_session/live_session_screen.dart';
import 'package:verifier_facl/main.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    // The initial route is a splash/loading screen
    initialLocation: '/splash',
    routes: [
      // This route uses your existing AuthWrapper to decide what to do first
      GoRoute(path: '/splash', builder: (context, state) => const AuthWrapper()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/classes', builder: (context, state) => const ClassListScreen()),
      GoRoute(path: '/create-class', builder: (context, state) => const CreateClassScreen()),
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
    // This redirect logic protects your routes
    redirect: (context, state) {
      // Use .asData to safely access the value
      final isAuthenticated = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/onboarding' ||
                          state.matchedLocation == '/splash';

      // If the user is not logged in and not on a login/splash page, redirect to login
      if (!isAuthenticated && !isLoggingIn) return '/login';
      
      // If the user is logged in and tries to go to login/onboarding, redirect to their classes
      if (isAuthenticated && isLoggingIn) return '/classes';
      
      return null; // No redirect needed
    },
  );
});
