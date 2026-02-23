import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_provider.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';
import '../../../services/firebase_service.dart';

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
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 🔥 CREATE USER DOCUMENT IF NOT EXIST
      final user = credential.user;
      if (user != null) {
        await FirebaseService().createUserIfNotExists(user);
      } else {
        throw Exception("Login success but user is null");
      }

      state = const AuthState();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// REGISTER
  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 🔥 CREATE USER DOCUMENT
      final user = credential.user;
      if (user != null) {
        await FirebaseService().createUserIfNotExists(user);
      } else {
        throw Exception("Register success but user is null");
      }

      state = const AuthState();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// LOGOUT
Future<void> logout() async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    await FirebaseAuth.instance.signOut();
    state = const AuthState();
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}



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
