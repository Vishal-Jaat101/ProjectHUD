import 'package:flutter/material.dart';

/// ProjectHUD Design System: "Asphalt + Signal Amber"
///
/// Inspired by road signage and safety equipment.
/// One colour = one meaning, always:
///   - Amber = guidance / caution
///   - Red = danger ONLY
///   - Green = verified ONLY
///
/// BANNED: gradients, glassmorphism, neon glow, purple/blue AI schemes,
/// gradient text, decorative shadows, generic tech-blue themes.

class AppColors {
  AppColors._();

  /// Background — asphalt near-black
  static const Color background = Color(0xFF0C0E0F);

  /// Panel / card background — dark grey
  static const Color panel = Color(0xFF16191B);

  /// Primary text — white
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Primary accent — Signal Amber (guidance, turns, brand)
  static const Color amber = Color(0xFFFFB300);

  /// Danger — Signal Red (hazard alerts ONLY)
  static const Color danger = Color(0xFFFF3B30);

  /// Verified — Green (consensus-confirmed states ONLY)
  static const Color verified = Color(0xFF35C759);

  /// Secondary text — cool grey
  static const Color textSecondary = Color(0xFF9BA1A6);

  /// Borders / dividers — dark line
  static const Color border = Color(0xFF26292C);

  /// Transparent overlay for modal backgrounds
  static const Color overlay = Color(0xCC0C0E0F);
}

class AppTypography {
  AppTypography._();

  // ── HUD numerals (Barlow Semi Condensed) ──────────────────────────
  // Must be readable at arm's length in sunlight.

  /// Speed display — the biggest number on screen
  static const TextStyle hudSpeed = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 96,
    height: 1.0,
    color: AppColors.amber,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Turn distance — large but secondary to speed
  static const TextStyle hudDistance = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 56,
    height: 1.1,
    color: AppColors.amber,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// ETA / remaining distance strip
  static const TextStyle hudInfo = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.2,
    color: AppColors.amber,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Unit labels (km, m, km/h)
  static const TextStyle hudUnit = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: AppColors.amber,
  );

  // ── App headings (Barlow Semi Condensed) ──────────────────────────

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ── Body text (Inter) ─────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  // ── Button text ───────────────────────────────────────────────────

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.2,
    color: AppColors.background,
    letterSpacing: 0.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'BarlowSemiCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.amber,
        secondary: AppColors.amber,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.background,
        onSecondary: AppColors.background,
        onError: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading2,
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.background,
          minimumSize: const Size(double.infinity, 64), // 64dp min touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.buttonLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.amber,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.amber, width: 2),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.panel,
        selectedItemColor: AppColors.amber,
        unselectedItemColor: AppColors.textSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.panel,
        contentTextStyle: AppTypography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
