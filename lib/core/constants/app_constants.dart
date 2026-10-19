import 'package:flutter/material.dart';


class AppConstants {
  AppConstants._();


  static const String appName = 'SmartHome';
  static const String appTitle = 'SmartHome IoT Controller';
  static const String appVersion = '1.2.0';
  static const String appBuild = 'Production Build';


  static const Color primaryPurple = Color(0xFF7B6EF5);
  static const Color primaryPurpleDark = Color(0xFF9E5CF6);
  static const Color accentBlue = Color(0xFF5DBEF5);
  static const Color accentOrange = Color(0xFFF5A25D);
  static const Color accentPink = Color(0xFFF55D8A);
  static const Color accentGreen = Color(0xFF11998E);


  static const List<List<Color>> avatarGradients = [
    [Color(0xFF7B6EF5), Color(0xFF9E5CF6)],
    [Color(0xFF5DBEF5), Color(0xFF3892F7)],
    [Color(0xFFF5A25D), Color(0xFFFA7268)],
    [Color(0xFFF55D8A), Color(0xFFE040FB)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
  ];


  static const String prefDarkMode = 'dark_mode_enabled';
  static const String prefNotifications = 'notifications_enabled';
  static const String prefActiveHome = 'active_home_id';
}
