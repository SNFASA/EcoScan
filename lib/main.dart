import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load environment variables first
    await dotenv.load(fileName: ".env");

    // 2. Initialize Firebase for all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. User Authentication Check (From Version 1)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseService().createUserIfNotExists(user);
    }

  } catch (e, stackTrace) {
    // 4. Catch all errors and show Fallback UI (From Version 2)
    debugPrint('⚠️ Failed to initialize app: $e');
    debugPrint('Stack trace:\n$stackTrace');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '⚠️ Failed to initialize the app.\n'
                    'Please restart or try again later.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
    return; // Stop execution here if it failed
  }

  // 5. Run the app if everything succeeded
  runApp(
    const ProviderScope(
      child: EcoScanApp(),
    ),
  );
}