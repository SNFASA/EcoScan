import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;

  /// Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  /// Email & Password Sign In
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Email & Password Register
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Google Sign-In
  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception("Google sign-in aborted");
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await auth.signInWithCredential(credential);
  }

  /// Sign Out
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await auth.signOut();
  }

  /// Auth state changes (very important)
  static Stream<User?> authStateChanges() {
    return auth.authStateChanges();
  }
}
