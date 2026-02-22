import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. CHANGED THE IMPORT HERE 👇
import '../features/auth/ui/welcome_screen.dart';
import '../features/home/ui/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F9F5),
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        // 2. Logged In -> Go to HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 3. Logged Out -> Go to WelcomeScreen instead of Login!
        return const WelcomeScreen(); // <--- CHANGED THIS LINE 👇
      },
    );
  }
}