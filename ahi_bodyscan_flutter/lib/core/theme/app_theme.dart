import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.secondaryBlue,
        tertiary: AppColors.accentPurple,
        surface: AppColors.backgroundWhite,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.backgroundCard,
        error: AppColors.error,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.headingSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        centerTitle: true,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundWhite,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          side: const BorderSide(color: AppColors.primaryPurple, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPlaceholder,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundWhite,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: AppColors.inactive,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: AppTypography.bodySmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.secondaryBlue,
        tertiary: AppColors.accentPurple,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textWhite,
        surfaceContainerHighest: AppColors.darkCard,
        error: AppColors.error,
      ),
      
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.headingSmall.copyWith(
          color: AppColors.textWhite,
        ),
        centerTitle: true,
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class AppDimensions {
  // Padding
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;

  // Spacing (same as padding for consistency)
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;

  // Radius
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusRound = 999;
  static const double radiusPill = 28;

  // Button heights
  static const double buttonHeight = 48; // Standard button height
  static const double buttonHeightSmall = 36;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 56;

  // Icon sizes
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
}

class AppShadows {
  static BoxShadow small = BoxShadow(
    color: AppColors.shadowLight,
    offset: const Offset(0, 2),
    blurRadius: 4,
  );
  
  static BoxShadow medium = BoxShadow(
    color: AppColors.shadowLight,
    offset: const Offset(0, 4),
    blurRadius: 8,
  );
  
  static BoxShadow large = BoxShadow(
    color: AppColors.shadowLight,
    offset: const Offset(0, 8),
    blurRadius: 16,
  );
  
  static BoxShadow elevation = BoxShadow(
    color: AppColors.shadowLight,
    offset: const Offset(0, 4),
    blurRadius: 10,
  );
}