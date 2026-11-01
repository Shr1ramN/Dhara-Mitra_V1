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
  Color? color,
}) => TextStyle(
  fontFamily: _displayFont,
  fontFamilyFallback: _fallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.2,
  height: 1.25,
);

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  if (brightness == Brightness.dark) return buildDarkTheme();
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
      headlineSmall: display(24, color: AppColors.text),
      titleLarge: display(20, color: AppColors.text),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.text,
      titleTextStyle: display(20, color: AppColors.text),
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

extension AppPaletteContext on BuildContext {
  AppPalette get appColors => AppPalette(Theme.of(this).brightness);
}

class AppPalette {
  const AppPalette(this.brightness);
  final Brightness brightness;
  bool get dark => brightness == Brightness.dark;
  Color get surface => dark ? const Color(0xFF202722) : AppColors.surface;
  Color get background => dark ? const Color(0xFF141A16) : AppColors.background;
  Color get border => dark ? const Color(0xFF465149) : AppColors.border;
  Color get text => dark ? const Color(0xFFF0F3EE) : AppColors.text;
  Color get textMuted => dark ? const Color(0xFFBDC9BE) : AppColors.textMuted;
  Color get accent => dark ? const Color(0xFFFFAB73) : AppColors.accent;
  Color get accentDark => dark ? const Color(0xFFFFBD93) : AppColors.accentDark;
  Color get accentSoft => dark ? const Color(0xFF493424) : AppColors.accentSoft;
  Color get okBg => dark ? const Color(0xFF233D2B) : AppColors.okBg;
  Color get okText => dark ? const Color(0xFFA8D9B4) : AppColors.okText;
  Color get warnBg => dark ? const Color(0xFF44391F) : AppColors.warnBg;
  Color get warnText => dark ? const Color(0xFFF0CF88) : AppColors.warnText;
  Color get infoBg => dark ? const Color(0xFF22374B) : AppColors.infoBg;
  Color get infoText => dark ? const Color(0xFFA9CDEB) : AppColors.infoText;
  Color get down => dark ? const Color(0xFFFFB4AB) : AppColors.down;
  Color get up => okText;
}

ThemeData buildDarkTheme() {
  const palette = AppPalette(Brightness.dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.accent,
    brightness: Brightness.dark,
    primary: palette.accent,
    onPrimary: const Color(0xFF362011),
    surface: palette.surface,
    onSurface: palette.text,
    error: palette.down,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    scaffoldBackgroundColor: palette.background,
  );
  final radius = BorderRadius.circular(14);
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineSmall: display(24, color: palette.text),
      titleLarge: display(20, color: palette.text),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: display(20, color: palette.text),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.border),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.accent, width: 1.6),
      ),
      labelStyle: TextStyle(color: palette.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamilyFallback: _fallback,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: palette.surface,
      selectedColor: palette.accentSoft,
      side: BorderSide(color: palette.border),
      labelStyle: TextStyle(color: palette.text, fontFamilyFallback: _fallback),
      checkmarkColor: palette.accent,
    ),
    dividerTheme: DividerThemeData(color: palette.border),
    tabBarTheme: TabBarThemeData(
      labelColor: palette.accent,
      unselectedLabelColor: palette.textMuted,
      indicatorColor: palette.accent,
      dividerColor: palette.border,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accentSoft,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.surface,
      contentTextStyle: TextStyle(color: palette.text),
    ),
  );
}
