import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return const AuthState();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> register({required String email, required String password}) {
    return _run(() => _repository.register(email: email, password: password));
  }

  Future<void> signOut() async {
    state = const AuthState(isLoading: true);
    try {
      await _repository.signOut();
      state = const AuthState();
    } on FirebaseAuthException catch (error) {
      state = AuthState(errorMessage: _messageFor(error));
    }
  }

  void clearError() {
    if (state.errorMessage != null) state = const AuthState();
  }

  Future<bool> _run(Future<Object?> Function() operation) async {
    state = const AuthState(isLoading: true);
    try {
      await operation();
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (error) {
      state = AuthState(errorMessage: _messageFor(error));
      return false;
    } catch (_) {
      state = const AuthState(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already uses this email.',
      'weak-password' => 'Use a password with at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' => 'Check your connection and try again.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
}
