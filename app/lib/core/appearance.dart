import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themePreferenceKey = 'appearance.theme';
ThemeMode parseThemeMode(String? value) =>
    ThemeMode.values.asNameMap()[value] ?? ThemeMode.system;
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);
  Future<void> set(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(themePreferenceKey, mode.name)) {
      throw StateError('Theme preference could not be saved');
    }
    if (ref.mounted) state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
