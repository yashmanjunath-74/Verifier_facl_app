import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifier_facl/core/models/faculty.dart';
import 'package:verifier_facl/core/providers/services_provider.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Faculty?>>((ref) {
      return AuthNotifier(ref);
    });

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref
          .watch(authNotifierProvider)
          .whenData((user) => user != null)
          .value ??
      false;
});

final currentFacultyProvider = Provider<Faculty?>((ref) {
  return ref.watch(authNotifierProvider).value;
});

class AuthNotifier extends StateNotifier<AsyncValue<Faculty?>> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final faculty = await _ref.read(authServiceProvider).currentFaculty;
      state = AsyncValue.data(faculty);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(authServiceProvider).signUp(username, password);
      await login(username, password); // Auto-login after sign up
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final faculty = await _ref
          .read(authServiceProvider)
          .login(username, password);
      state = AsyncValue.data(faculty);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(authServiceProvider).logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
