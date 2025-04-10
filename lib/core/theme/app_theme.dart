import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';
import 'text_styles.dart';

/// Theme data and configuration
class AppTheme {
  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ColorPalette.primary,
      scaffoldBackgroundColor: ColorPalette.background,
      colorScheme: ColorScheme.light(
        primary: ColorPalette.primary,
        secondary: ColorPalette.secondary,
        background: ColorPalette.background,
        surface: ColorPalette.surface,
        onPrimary: ColorPalette.onPrimary,
        onSecondary: ColorPalette.onSecondary,
        onBackground: ColorPalette.onBackground,
        onSurface: ColorPalette.onSurface,
        error: ColorPalette.error,
        onError: ColorPalette.onError,
      ),
      // Card theme
      cardTheme: CardTheme(
        color: ColorPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
      ),
      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: ColorPalette.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
      ),
      // Text theme
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
      ),
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: ColorPalette.onBackground,
        ),
        iconTheme: IconThemeData(
          color: ColorPalette.onBackground,
        ),
      ),
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ColorPalette.surface,
        selectedItemColor: ColorPalette.primary,
        unselectedItemColor: ColorPalette.onSurfaceVariant,
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: ColorPalette.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: ColorPalette.error,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
      ),
      useMaterial3: true,
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ColorPalette.primary,
      scaffoldBackgroundColor: ColorPalette.backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: ColorPalette.primary,
        secondary: ColorPalette.secondary,
        background: ColorPalette.backgroundDark,
        surface: ColorPalette.surfaceDark,
        onPrimary: ColorPalette.onPrimary,
        onSecondary: ColorPalette.onSecondary,
        onBackground: ColorPalette.onBackgroundDark,
        onSurface: ColorPalette.onSurfaceDark,
        error: ColorPalette.error,
        onError: ColorPalette.onError,
      ),
      // Card theme
      cardTheme: CardTheme(
        color: ColorPalette.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
      ),
      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: ColorPalette.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
      ),
      // Text theme
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: ColorPalette.onBackgroundDark,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: ColorPalette.onBackgroundDark,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: ColorPalette.onBackgroundDark,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: ColorPalette.onBackgroundDark,
        ),
      ),
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.backgroundDark,
        elevation: 0,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: ColorPalette.onBackgroundDark,
        ),
        iconTheme: IconThemeData(
          color: ColorPalette.onBackgroundDark,
        ),
      ),
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ColorPalette.surfaceDark,
        selectedItemColor: ColorPalette.primary,
        unselectedItemColor: ColorPalette.onSurfaceVariantDark,
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: ColorPalette.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: ColorPalette.error,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
      ),
      useMaterial3: true,
    );
  }
}
