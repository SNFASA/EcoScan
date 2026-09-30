import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

// 🟢 DATA PROVIDER: Keep this as StreamProvider so your UI doesn't break
final userControllerProvider = StreamProvider.family<UserModel, String>((ref, uid) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUser(uid);
});

// 🔵 ACTION PROVIDER: Use this for updating profile settings
final userProfileActionsProvider = Provider((ref) => UserProfileActions(ref));

class UserProfileActions {
  final Ref ref;
  UserProfileActions(this.ref);

  Future<void> updateProfile({
    required String username, 
    required String email, 
    String? profileUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final updates = {
      'username': username,
      'email': email,
      // Use the null-aware spread as suggested by your diagnostic
      ...?profileUrl != null ? {'profileurl': profileUrl} : null,
    };

    await ref.read(userRepositoryProvider).updateUserSettings(uid, updates);
  }
}