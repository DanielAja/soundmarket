import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';

/// Typography styles
class AppTextStyles {
  // Headings
  static final TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ColorPalette.textPrimary,
    letterSpacing: -0.5,
  );
  
  static final TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: ColorPalette.textPrimary,
    letterSpacing: -0.5,
  );
  
  static final TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
    letterSpacing: -0.25,
  );
  
  static final TextStyle heading4 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
    letterSpacing: -0.25,
  );
  
  // Titles
  static final TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
  );
  
  static final TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
  );
  
  static final TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
  );
  
  // Body text
  static final TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: ColorPalette.textPrimary,
  );
  
  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: ColorPalette.textSecondary,
  );
  
  static final TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: ColorPalette.textSecondary,
  );
  
  // Labels
  static final TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorPalette.textSecondary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorPalette.textSecondary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: ColorPalette.textTertiary,
    letterSpacing: 0.5,
  );
  
  // Buttons
  static final TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorPalette.onPrimary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorPalette.onPrimary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ColorPalette.onPrimary,
    letterSpacing: 0.5,
  );
  
  // Price text
  static final TextStyle priceUp = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorPalette.priceUp,
  );
  
  static final TextStyle priceDown = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorPalette.priceDown,
  );
  
  // Currency text
  static final TextStyle currency = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ColorPalette.onBackground,
  );
  
  static final TextStyle currencyLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: ColorPalette.onBackground,
  );
  
  // Chart labels
  static final TextStyle chartLabel = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: ColorPalette.onSurfaceVariant,
  );
  
  // Helper methods to get dark theme variants
  static TextStyle withDarkColor(TextStyle style) {
    // Map light theme colors to dark theme equivalents
    Color darkColor;
    if (style.color == ColorPalette.textPrimary) {
      darkColor = ColorPalette.textPrimaryDark;
    } else if (style.color == ColorPalette.textSecondary) {
      darkColor = ColorPalette.textSecondaryDark;
    } else if (style.color == ColorPalette.textTertiary) {
      darkColor = ColorPalette.textTertiaryDark;
    } else {
      darkColor = ColorPalette.onBackgroundDark;
    }
    
    return style.copyWith(
      color: darkColor,
    );
  }
  
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(
      color: color,
    );
  }
  
  // Caption text
  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: ColorPalette.textTertiary,
    letterSpacing: 0.4,
  );
}
