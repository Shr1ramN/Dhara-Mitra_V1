import 'package:flutter/material.dart';

import 'enums.dart';

/// Colours from the prototype (white + orange, plan section 7).
abstract final class AppColors {
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFBF8F5);
  static const border = Color(0xFFEEE7DE);
  static const text = Color(0xFF1C1A17);
  static const textMuted = Color(0xFF6B645B);
  static const accent = Color(0xFFE8712A);
  static const accentDark = Color(0xFFC85E1F);
  static const accentSoft = Color(0xFFFDEFE3);
  static const up = Color(0xFF2E8B57);
  static const down = Color(0xFFC0392B);
  static const okBg = Color(0xFFEAF4EE);
  static const okText = Color(0xFF23704A);
  static const warnBg = Color(0xFFFFF4D6);
  static const warnText = Color(0xFF8A6100);
  static const infoBg = Color(0xFFE8F1FA);
  static const infoText = Color(0xFF2F6699);

  static Color crop(Crop crop) => switch (crop) {
    Crop.areca => const Color(0xFF2E8B57),
    Crop.coconut => const Color(0xFF8B5E34),
    Crop.pepper => const Color(0xFFB23A3A),
    Crop.banana => const Color(0xFFD4A106),
  };
}

const _bodyFont = 'Inter';
const _displayFont = 'SpaceGrotesk';
const _fallback = ['NotoSansKannada'];

/// Kannada has no glyphs in Inter or Space Grotesk, so it falls back to Noto Sans Kannada.
TextStyle display(
  double size, {
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.text,
}) => TextStyle(
  fontFamily: _displayFont,
  fontFamilyFallback: _fallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.2,
  height: 1.25,
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.accentDark,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.down,
  );
  final radius = BorderRadius.circular(14);
  final fieldRadius = BorderRadius.circular(12);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    scaffoldBackgroundColor: AppColors.background,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: display(24),
      titleLarge: display(20),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.text,
      titleTextStyle: display(20),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          fontFamilyFallback: _fallback,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamilyFallback: _fallback,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accentDark),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accentSoft,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w500,
        fontFamilyFallback: _fallback,
      ),
      checkmarkColor: AppColors.accentDark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accentSoft,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: _fallback,
          color: s.contains(WidgetState.selected)
              ? AppColors.accentDark
              : AppColors.textMuted,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.accentSoft,
        selectedForegroundColor: AppColors.accentDark,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.accentDark,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.accent,
      dividerColor: AppColors.border,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.text),
  );
}
