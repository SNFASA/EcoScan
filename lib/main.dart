import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables first
    await dotenv.load(fileName: ".env");

    // Initialize Firebase for all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // You can initialize any other services here if needed
  } catch (e, stackTrace) {
    // Catch all errors during initialization
    debugPrint('⚠️ Failed to initialize app: $e');
    debugPrint('Stack trace:\n$stackTrace');

    // Show fallback error UI
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
    return;
  }

  // Run the app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: EcoScanApp(),
    ),
  );
}
