import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService.initialize(); // Initialize Firebase
    await dotenv.load(fileName: ".env"); // Load secrets
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize app: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize the app. Please restart or try again later.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    const ProviderScope(
      child: EcoScanApp(),
    ),
  );
}
