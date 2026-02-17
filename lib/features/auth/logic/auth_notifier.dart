import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_provider.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository repository;

  @override
  AuthState build() {
    repository = ref.read(authRepositoryProvider);
    return const AuthState();
  }

  /// LOGIN
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repository.login(email, password);

      // Reset state after success
      state = const AuthState();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Something went wrong",
      );
    }
  }

  /// REGISTER
  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repository.register(email, password);
      state = const AuthState();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Something went wrong",
      );
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await repository.logout();
  }

  /// Better Firebase error mapping
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'User not found.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}
