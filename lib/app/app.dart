import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../features/auth/ui/login_screen.dart';

class EcoScanApp extends StatelessWidget {
  const EcoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoScan',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
