import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/home/ui/home_screen.dart'; //

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Logged In -> Go to HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen(); // <--- CHANGED THIS LINE
        }

        // 3. Logged Out -> Go to Login
        return const LoginScreen();
      },
    );
  }
}