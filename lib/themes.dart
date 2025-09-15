import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show ThemeData;

// Dark theme definition
final FluentThemeData darkTheme = FluentThemeData(
  brightness: Brightness.dark,
  accentColor: Colors.blue,
  visualDensity: VisualDensity.standard,
);

// Light theme definition
final FluentThemeData lightTheme = FluentThemeData(
  brightness: Brightness.light,
  accentColor: Colors.blue,
  visualDensity: VisualDensity.standard,
);

// Material dark theme for settings page
final ThemeData darkMaterialTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1F2A29),
  cardColor: const Color(0xFF2D3A3A),
);

// Material light theme for settings page
final ThemeData lightMaterialTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  cardColor: const Color(0xFFFFFFFF),
);

// Get theme data based on theme mode
FluentThemeData getFluentTheme(bool isDark) {
  return isDark ? darkTheme : lightTheme;
}

// Get material theme data based on theme mode
ThemeData getMaterialTheme(bool isDark) {
  return isDark ? darkMaterialTheme : lightMaterialTheme;
}
