import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryBlue = Color(0xFF4FC3F7);
  static const Color primaryGreen = Color(0xFF66BB6A);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // Accent colors
  static const Color accentBlue = Color(0xFF81D4FA);
  static const Color accentGreen = Color(0xFFC8E6C9);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // Icon colors
  static const Color strokeColor = Colors.white;
}

class AppTheme {
  static const _Colors colors = _Colors();
}

class _Colors {
  const _Colors();

  Color get strokeColor => AppColors.strokeColor;
}

