import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static String get fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  // Heading styles
  static TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    fontFamily: fontFamily,
  );

  static TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    fontFamily: fontFamily,
  );

  static TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    fontFamily: fontFamily,
  );

  // Body styles
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    fontFamily: fontFamily,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    fontFamily: fontFamily,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    fontFamily: fontFamily,
  );

  // Button styles
  static TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    fontFamily: fontFamily,
  );

  static TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    fontFamily: fontFamily,
  );

  // Material Design aliases for compatibility
  static TextStyle get displayLarge => TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 64 / 57,
        fontFamily: fontFamily,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 52 / 45,
        fontFamily: fontFamily,
      );

  static TextStyle get displaySmall => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 44 / 36,
        fontFamily: fontFamily,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        fontFamily: fontFamily,
      );

  static TextStyle get headlineMedium => headingMedium; // Alias

  static TextStyle get headlineSmall => headingSmall; // Alias
}