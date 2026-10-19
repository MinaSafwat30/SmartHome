import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);

Future<void> toggleAppTheme([bool? forceDark]) async {
  final currentIsDark = themeModeNotifier.value == ThemeMode.dark;
  final newIsDark = forceDark ?? !currentIsDark;
  themeModeNotifier.value = newIsDark ? ThemeMode.dark : ThemeMode.light;

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', newIsDark);
  } catch (_) {}
}

const kPurple = Color(0xFF7B6EF5);
const kPurpleDark = Color(0xFF9E5CF6);

extension SmartTheme on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get bgCol =>
      isDarkMode ? const Color(0xFF0F111E) : const Color(0xFFF4F6FB);

  Color get cardCol => isDarkMode ? const Color(0xFF191C2E) : Colors.white;

  Color get cardSubtleCol =>
      isDarkMode ? const Color(0xFF23273D) : const Color(0xFFF4F6FB);

  Color get textPrimaryCol =>
      isDarkMode ? const Color(0xFFF0F2FA) : const Color(0xFF1E2340);

  Color get textSecondaryCol =>
      isDarkMode ? const Color(0xFF9FA7C5) : const Color(0xFF8A91B4);

  Color get dividerCol =>
      isDarkMode ? const Color(0xFF252940) : const Color(0xFFEEEFF7);

  Color get inputFillCol =>
      isDarkMode ? const Color(0xFF23273D) : const Color(0xFFF4F6FB);
}

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4F6FB),
  cardColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPurple,
    brightness: Brightness.light,
    surface: Colors.white,
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
  ),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0F111E),
  cardColor: const Color(0xFF191C2E),
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPurple,
    brightness: Brightness.dark,
    surface: const Color(0xFF191C2E),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF191C2E)),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
  ),
);
