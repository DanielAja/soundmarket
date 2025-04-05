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
  static const Color onBackground = Colors.black;
  static const Color backgroundDark = Colors.black;
  static const Color onBackgroundDark = Colors.white;
  
  // Surface colors
  static const Color surface = Color(0xFFF5F5F5);
  static const Color onSurface = Colors.black;
  static const Color surfaceDark = Color(0xFF121212);
  static const Color onSurfaceDark = Colors.white;
  
  // Variant colors
  static const Color surfaceVariant = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFF666666);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  static const Color onSurfaceVariantDark = Color(0xFFAAAAAA);
  
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
