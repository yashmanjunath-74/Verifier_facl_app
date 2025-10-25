import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifier_facl/core/navigation/app_router.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/features/auth/login_screen.dart';
import 'package:verifier_facl/features/class_management/class_list_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database BEFORE running the app
  final database = await initDatabase();

  // Pass the initialized database to the app
  runApp(
    ProviderScope(
      overrides: [
        // Override the databaseProvider to provide the actual database instance
        databaseProvider.overrideWithValue(database),
      ],
      child: const VerifierFacultyApp(),
    ),
  );
}

class VerifierFacultyApp extends ConsumerWidget {
  const VerifierFacultyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the provider to get the router instance
    final router = ref.watch(routerProvider);

    // We use MaterialApp.router instead of the default MaterialApp
    return MaterialApp.router(
      title: 'Verifier Faculty App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      // We pass our router configuration to the app
      routerConfig: router,
    );
  }
}

// This AuthWrapper is still used by our router for the initial splash route
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (faculty) =>
          faculty != null ? const ClassListScreen() : const LoginScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('An error occurred: $err')),
      ),
    );
  }
}

