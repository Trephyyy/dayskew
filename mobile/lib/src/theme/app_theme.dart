import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme for the DaySkew mobile app: Hack Club neo-brutalism meets
/// Stardance retro-arcade. Thick borders, hard offset shadows, mono metrics.
abstract final class AppTheme {
  /// Monospace family used for raw time/metric chips. Falls back gracefully
  /// when the font is unavailable on the host platform.
  static const String monoStack = 'monospace';

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.medium,
        secondary: AppColors.high,
        surface: AppColors.surface,
        error: AppColors.conflict,
        onPrimary: AppColors.canvas,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'sans-serif',
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 2),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.medium,
          foregroundColor: AppColors.canvas,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  static TextStyle get h1 => const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 26,
        height: 1.15,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        height: 1.2,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 14,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMuted => const TextStyle(
        fontSize: 13,
        height: 1.4,
        color: AppColors.textMuted,
      );

  static TextStyle get mono => const TextStyle(
        fontFamily: monoStack,
        fontSize: 13,
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );
}