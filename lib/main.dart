import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only now you can access FirebaseAuth
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirebaseService().createUserIfNotExists(user);
  }

  runApp(
    const ProviderScope(child: EcoScanApp()),
  );
}

