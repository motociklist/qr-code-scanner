import 'package:flutter/material.dart';

class AppStyles {
  // Typography styles based on design system

  // Large Title - 34px / Bold (700)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  // Title 1 - 28px / Bold (700)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  // Title 2 - 22px / Semibold (600)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  // Body / Paragraph - 17px / Regular (400)
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  // Caption / Small - 15px / Regular (400)
  static const TextStyle caption = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  // Button Text - 17px / Semibold (600)
  static const TextStyle buttonText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  // TAB BAR LABEL - 10px / Medium (500)
  static const TextStyle tabBarLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  // Legacy styles for backward compatibility (deprecated - use new styles above)
  @Deprecated('Use title1 instead')
  static const TextStyle heading1 = title1;

  @Deprecated('Use title2 instead')
  static const TextStyle heading2 = title2;

  @Deprecated('Use title2 instead')
  static const TextStyle heading3 = title2;

  @Deprecated('Use body instead')
  static const TextStyle bodyLarge = body;

  @Deprecated('Use caption instead')
  static const TextStyle bodyMedium = caption;

  @Deprecated('Use caption instead')
  static const TextStyle bodySmall = caption;

  static TextStyle bodySecondary = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: Colors.grey[600],
  );

  static TextStyle bodyTertiary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
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

