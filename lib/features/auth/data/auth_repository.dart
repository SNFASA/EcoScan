// only talks to firebase auth, abstracts away the details from the rest of the app
// UI never touches firebase directly, makes it easier to switch auth providers if needed
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithEmail(
      String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
