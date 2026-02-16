// all logic goes here, such as sign in, sign up, sign out, etc.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;

  AuthNotifier(this.repository) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true);

    try {
      await repository.signInWithEmail(email, password);
      state = const AuthState();
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }
}

