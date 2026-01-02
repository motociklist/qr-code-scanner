import 'package:flutter/material.dart';

class AppStyles {
  // Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.black,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.black,
  );

  static TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
  );

  static TextStyle bodyTertiary = TextStyle(
    fontSize: 12,
    color: Colors.grey[500],
  );

  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration cardDecorationSmall = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.05),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

