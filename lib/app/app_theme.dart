// Centralized colors and style makes Ui consistent 
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Colors.green,
      useMaterial3: true,
    );
  }
}
