import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthome/core/config/app_secrets.dart';
import 'package:smarthome/core/theme/app_theme.dart';
import 'package:smarthome/features/Auth/auth.dart';
export 'package:smarthome/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: AppSecrets.firebaseOptions);
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode_enabled') ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {}

  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Home',
          themeMode: currentMode,
          theme: appLightTheme,
          darkTheme: appDarkTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}
