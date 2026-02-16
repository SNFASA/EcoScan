// this connects everything together, such as the provider, notifier, and state.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});

