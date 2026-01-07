import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  // Typography styles based on design system

  // Large Title - 34px / Bold (700)
  static TextStyle get largeTitle => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      );

  // Title 1 - 28px / Bold (700)
  static TextStyle get title1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      );

  // Title 2 - 22px / Semibold (600)
  static TextStyle get title2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  // Title 3 - 22px / Semibold (600) / Letter Spacing -0.5px / Color #111111
  static TextStyle get title3 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: const Color(0xFF111111),
      );

  // Body / Paragraph - 17px / Regular (400)
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  // Body Medium - 17px / Medium (500) / Letter Spacing -0.5px / Line Height 26 / Color #111111
  static TextStyle get bodyMediumText => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: const Color(0xFF111111),
      );

  // Button Action Text - 17px / Semi Bold (600) / Letter Spacing -0.5px / Line Height 26
  static TextStyle get buttonActionText => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Colors.white,
      );

  // Caption / Small - 15px / Medium (500) / Letter Spacing -0.5px / Color #5A5A5A
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFF5A5A5A),
      );

  // Small Text - 13px / Regular (400) / Letter Spacing -0.5px / Line Height 20 / Color #B0B0B0
  static TextStyle get smallText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFFB0B0B0),
      );

  // Small Text Gray - 13px / Regular (400) / Letter Spacing -0.5px / Color #5A5A5A
  static TextStyle get smallTextGray => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFF5A5A5A),
      );

  // Design Option Label - 15px / Medium (500) / Letter Spacing -0.5px / Color #111111
  static TextStyle get designOptionLabel => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: const Color(0xFF111111),
      );

  // Pro Feature Badge - 13px / Regular (400) / Letter Spacing -0.5px / Color #5A5A5A
  static TextStyle get proFeatureBadge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFF5A5A5A),
      );

  // Card Title - 15px / Semi Bold (600) / Letter Spacing -0.5px / Line Height 23 / Color #111111
  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: const Color(0xFF111111),
      );

  // Card Date - 12px / Regular (400) / Letter Spacing -0.5px / Line Height 18 / Color #B0B0B0
  static TextStyle get cardDate => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFFB0B0B0),
      );

  // Button Text - 17px / Semibold (600)
  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  // TAB BAR LABEL - 10px / Medium (500) / Line Height 15 / Letter Spacing -0.5px
  static TextStyle get tabBarLabel => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: Colors.black,
      );

  // Legacy styles for backward compatibility (deprecated - use new styles above)
  @Deprecated('Use title1 instead')
  static TextStyle get heading1 => title1;

  @Deprecated('Use title2 instead')
  static TextStyle get heading2 => title2;

  @Deprecated('Use title2 instead')
  static TextStyle get heading3 => title2;

  @Deprecated('Use body instead')
  static TextStyle get bodyLarge => body;

  @Deprecated('Use caption instead')
  static TextStyle get bodyMedium => caption;

  @Deprecated('Use caption instead')
  static TextStyle get bodySmall => caption;

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Colors.grey[600],
      );

  static TextStyle get bodyTertiary => GoogleFonts.inter(
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
