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
      // Map the underlying error to a user-facing message.
      state = AuthState(error: _mapErrorToMessage(e));
    }
  }

  String _mapErrorToMessage(Object error) {
    if (error is FormatException) {
      return 'The provided credentials are in an invalid format.';
    }

    return error.toString();
  }
}
