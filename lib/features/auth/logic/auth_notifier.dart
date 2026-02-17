import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repository.signInWithEmail(email, password);
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapErrorToMessage(e),
      );
    }
  }

  String _mapErrorToMessage(Object error) {
    if (error is FormatException) {
      return 'The provided credentials are in an invalid format.';
    }
    return error.toString();
  }
}
