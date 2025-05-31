import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    primary: Color(0xFF1976D2),
    secondary: Color(0xFFCCCCCC),
    onBackground: Color(0xFF000000),
    onSurface: Color(0xFF5A5A5A),
    outline: Color(0xFFE0E0E0),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    tertiary: Color(0xFF1976D2),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  cardColor: const Color(0xFFF5F5F5),
  dividerColor: const Color(0xFFE0E0E0),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF000000),
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF000000)),
     titleTextStyle: TextStyle(
      color: Color(0xFF000000),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFE8E8E8),
    labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
    hintStyle: const TextStyle(color: Color(0xFF5A5A5A)),
    prefixIconColor: const Color(0xFF5A5A5A),
    suffixIconColor: const Color(0xFF5A5A5A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1976D2)),
    ),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: Color(0xFF000000)),
    titleMedium: TextStyle(color: Color(0xFF000000)),
    bodyLarge: TextStyle(color: Color(0xFF5A5A5A)),
    bodyMedium: TextStyle(color: Color(0xFF5A5A5A)),
    labelLarge: TextStyle(color: Color(0xFF000000)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1976D2),
      foregroundColor: const Color(0xFFFFFFFF),
      disabledBackgroundColor: const Color(0xFFCCCCCC),
      disabledForegroundColor: const Color(0xFF5A5A5A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF1976D2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: Color(0xFF000000),
  ),
);
