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
      final errorMessage = _mapFirebaseError(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      throw Exception(errorMessage); // 🌟 ADDED: Throw it back to the UI!
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw Exception(e.toString()); // 🌟 ADDED: Throw it back to the UI!
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
      final errorMessage = _mapFirebaseError(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      throw Exception(errorMessage); // 🌟 ADDED: Throw it back to the UI!
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw Exception(e.toString()); // 🌟 ADDED: Throw it back to the UI!
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
      throw Exception(e.toString()); // Keep consistent error handling
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
    // Note: Firebase updated their errors. 'invalid-credential' is often thrown now instead of wrong-password
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}