import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth auth;

  AuthRepository({required this.auth});

  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await auth.signOut();
  }
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) throw "User not found";

  // 1. Re-authenticate the user (Required by Firebase for security)
  AuthCredential credential = EmailAuthProvider.credential(
    email: user.email!,
    password: currentPassword,
  );

  await user.reauthenticateWithCredential(credential);

  // 2. Update to new password
  await user.updatePassword(newPassword);
}
}
