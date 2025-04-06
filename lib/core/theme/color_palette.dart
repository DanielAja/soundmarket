import 'package:flutter/material.dart';

/// Color definitions
class ColorPalette {
  // Primary colors
  static const Color primary = Color(0xFF00D632); // Cash App green
  static const Color onPrimary = Colors.black;
  
  // Secondary colors
  static const Color secondary = Color(0xFF00C2FF); // Cash App blue accent
  static const Color onSecondary = Colors.black;
  
  // Background colors
  static const Color background = Colors.white;
  static const Color onBackground = Color(0xFF121212); // Softer than pure black
  static const Color backgroundDark = Color(0xFF121212); // Slightly lighter than pure black
  static const Color onBackgroundDark = Color(0xFFF5F5F5); // Softer than pure white
  
  // Surface colors
  static const Color surface = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF212121); // Slightly softer than pure black
  static const Color surfaceDark = Color(0xFF1E1E1E); // Slightly lighter than background
  static const Color onSurfaceDark = Color(0xFFECECEC); // Softer than pure white
  
  // Variant colors
  static const Color surfaceVariant = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFF555555); // Darker for better contrast
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  static const Color onSurfaceVariantDark = Color(0xFFBBBBBB); // Brighter for better contrast
  
  // Error colors
  static const Color error = Color(0xFFB00020);
  static const Color onError = Colors.white;
  
  // Success colors
  static const Color success = Color(0xFF00C853);
  static const Color onSuccess = Colors.white;
  
  // Warning colors
  static const Color warning = Color(0xFFFFAB00);
  static const Color onWarning = Colors.black;
  
  // Info colors
  static const Color info = Color(0xFF2196F3);
  static const Color onInfo = Colors.white;
  
  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF00D632), // Primary
    Color(0xFF00C2FF), // Secondary
    Color(0xFFFF9500), // Orange
    Color(0xFFFF2D55), // Red
    Color(0xFF5856D6), // Purple
    Color(0xFFAF52DE), // Pink
    Color(0xFF34C759), // Green
    Color(0xFF007AFF), // Blue
  ];
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D632), Color(0xFF00A726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00C2FF), Color(0xFF0096FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Price change colors
  static const Color priceUp = Color(0xFF00D632);
  static const Color priceDown = Color(0xFFFF2D55);
  
  // Text colors
  static const Color textPrimary = Color(0xFF121212); // Main text color (light theme)
  static const Color textSecondary = Color(0xFF555555); // Secondary text (light theme)
  static const Color textTertiary = Color(0xFF757575); // Tertiary text (light theme)
  static const Color textPrimaryDark = Color(0xFFF5F5F5); // Main text color (dark theme)
  static const Color textSecondaryDark = Color(0xFFBBBBBB); // Secondary text (dark theme)
  static const Color textTertiaryDark = Color(0xFF999999); // Tertiary text (dark theme)
  
  // Neutral colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
}
