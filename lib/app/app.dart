import 'package:flutter/material.dart';
import 'auth_gate.dart';

import 'app_theme.dart';
import '../features/auth/ui/login_screen.dart';

class EcoScanApp extends StatelessWidget {
  const EcoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // The Gate decides where to go!
      home: const AuthGate(),
    );
  }
}
