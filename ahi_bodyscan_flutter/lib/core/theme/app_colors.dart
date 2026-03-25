import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryPurple = Color(0xFF6A00FF);
  static const Color primaryBlue = Color(0xFF00B2FF);
  static const Color primary = primaryPurple; // Default primary color
  static const Color secondaryBlue = Color(0xFF4A90E2);
  static const Color accentPurple = Color(0xFF7B61FF);
  static const Color accentTeal = Color(0xFF00BCD4);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF111111);
  static const Color backgroundModal = Color(0xFFF0FAFF);
  static const Color backgroundCard = Color(0xFFE8EAF6);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  
  // Text colors
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF8A8A8E);
  static const Color textPlaceholder = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLabel = Color(0xFF333333);
  
  // Border and divider colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFCCCCCC);
  static const Color borderAccent = Color(0xFFA0E6FF);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF29B6F6);
  
  // Shadow colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadow = Color(0x1A000000);
  
  // Special colors
  static const Color transparent = Colors.transparent;
  static const Color inactive = Color(0xFF757575);
  static const Color activeTab = Color(0xFF6A00FF);
  
  // Dark theme specific
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [secondaryBlue, accentPurple],
  );

  static const LinearGradient primaryReverseGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentPurple, secondaryBlue],
  );

  static const LinearGradient cardBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundLight, backgroundCard],
  );
}