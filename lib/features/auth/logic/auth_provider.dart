import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// FirebaseAuth provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// AuthRepository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.read(firebaseAuthProvider);
  return AuthRepository(auth: auth);
});

/// AuthNotifier provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});
