import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background     = Color(0xFF141313);
  static const Color surfaceLowest  = Color(0xFF0E0E0E);
  static const Color surfaceLow     = Color(0xFF1C1B1B);
  static const Color surface        = Color(0xFF201F1F);
  static const Color surfaceHigh    = Color(0xFF2A2A2A);
  static const Color surfaceVariant = Color(0xFF353434);
  static const Color surfaceBright  = Color(0xFF3A3939);

  static const Color onBackground   = Color(0xFFE5E2E1);
  static const Color onSurface      = Color(0xFFE5E2E1);
  static const Color onSurfaceVar   = Color(0xFFC4C7C8);
  static const Color onSecContainer = Color(0xFFBAB8B7);

  static const Color primary        = Color(0xFFFFFFFF);
  static const Color onPrimary      = Color(0xFF2F3131);

  static const Color outline        = Color(0xFF8E9192);
  static const Color outlineVariant = Color(0xFF444748);

  static const Color error          = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color tertiaryBlue   = Color(0xFF1854EF);

  // Status colours
  static const Color criticalRed    = Color(0xFFEF4444);
  static const Color warningAmber   = Color(0xFFF59E0B);
  static const Color safeGreen      = Color(0xFF10B981);

  // Glass helpers
  static Color glassWhite(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => Colors.black.withValues(alpha: opacity);
}

class AppTextStyles {
  static TextStyle h1({Color color = AppColors.onBackground}) =>
    GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700,
      height: 1.1, letterSpacing: -0.96, color: color);

  static TextStyle h2({Color? color}) =>
    GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w600,
      height: 1.2, letterSpacing: -0.32, color: color ?? AppColors.onBackground);

  static TextStyle h3({Color color = AppColors.onBackground}) =>
    GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600,
      height: 1.3, color: color);

  static TextStyle bodyLg({Color color = AppColors.onBackground}) =>
    GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w400,
      height: 1.6, color: color);

  static TextStyle bodyMd({Color color = AppColors.onBackground}) =>
    GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400,
      height: 1.6, color: color);

  static TextStyle technical({Color color = AppColors.onBackground}) =>
    GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500,
      letterSpacing: 0.7, color: color);

  static TextStyle labelCaps({Color color = AppColors.onBackground}) =>
    GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700,
      letterSpacing: 1.2, color: color);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}
