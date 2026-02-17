import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.read(firebaseAuthProvider),
  );
});

/// ✅ MODERN Riverpod provider
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
