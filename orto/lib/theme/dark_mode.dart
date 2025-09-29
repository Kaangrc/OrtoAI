import 'package:flutter/material.dart';

// Modern iOS Dark Mode renk paleti
class ModernDarkColors {
  static const Color primary = Color(0xFF0A84FF); // iOS Dark Blue
  static const Color secondary = Color(0xFF30D158); // iOS Dark Green
  static const Color background = Color(0xFF000000); // iOS Dark Background
  static const Color card = Color(0xFF1C1C1E); // iOS Dark Card
  static const Color textPrimary = Color(0xFFFFFFFF); // iOS Dark Label
  static const Color textSecondary =
      Color(0xFF8E8E93); // iOS Dark Secondary Label
  static const Color error = Color(0xFFFF453A); // iOS Dark Red
  static const Color divider = Color(0xFF38383A); // iOS Dark Separator
  static const Color surfaceVariant =
      Color(0xFF1C1C1E); // iOS Dark Grouped Background
}

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    background: ModernDarkColors.background,
    surface: ModernDarkColors.card,
    primary: ModernDarkColors.primary,
    secondary: ModernDarkColors.secondary,
    onBackground: ModernDarkColors.textPrimary,
    onSurface: ModernDarkColors.textPrimary,
    outline: ModernDarkColors.divider,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    tertiary: ModernDarkColors.primary,
    error: ModernDarkColors.error,
    surfaceVariant: ModernDarkColors.surfaceVariant,
  ),
  scaffoldBackgroundColor: ModernDarkColors.background,
  cardColor: ModernDarkColors.card,
  dividerColor: ModernDarkColors.divider,
  appBarTheme: const AppBarTheme(
    backgroundColor: ModernDarkColors.card,
    foregroundColor: ModernDarkColors.textPrimary,
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(
      color: ModernDarkColors.textPrimary,
      size: 24,
    ),
    titleTextStyle: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      fontFamily: 'SF Pro Display',
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ModernDarkColors.card,
    labelStyle: const TextStyle(
      color: ModernDarkColors.textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: 'SF Pro Text',
    ),
    hintStyle: const TextStyle(
      color: ModernDarkColors.textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: 'SF Pro Text',
    ),
    floatingLabelStyle: const TextStyle(
      color: ModernDarkColors.primary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: 'SF Pro Text',
    ),
    prefixIconColor: ModernDarkColors.textSecondary,
    suffixIconColor: ModernDarkColors.textSecondary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ModernDarkColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ModernDarkColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ModernDarkColors.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFamily: 'SF Pro Display',
    ),
    displayMedium: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      fontFamily: 'SF Pro Display',
    ),
    displaySmall: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      fontFamily: 'SF Pro Display',
    ),
    headlineLarge: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      fontFamily: 'SF Pro Display',
    ),
    headlineMedium: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      fontFamily: 'SF Pro Display',
    ),
    headlineSmall: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      fontFamily: 'SF Pro Display',
    ),
    titleLarge: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    titleMedium: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    titleSmall: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    bodyLarge: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    bodyMedium: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    bodySmall: TextStyle(
      color: ModernDarkColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    labelLarge: TextStyle(
      color: ModernDarkColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    labelMedium: TextStyle(
      color: ModernDarkColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
    labelSmall: TextStyle(
      color: ModernDarkColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      fontFamily: 'SF Pro Text',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ModernDarkColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: ModernDarkColors.divider,
      disabledForegroundColor: ModernDarkColors.textSecondary,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        fontFamily: 'SF Pro Text',
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ModernDarkColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        fontFamily: 'SF Pro Text',
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ModernDarkColors.primary,
      side: const BorderSide(color: ModernDarkColors.primary, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        fontFamily: 'SF Pro Text',
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: ModernDarkColors.textPrimary,
    size: 24,
  ),
  cardTheme: CardTheme(
    color: ModernDarkColors.card,
    elevation: 0,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: ModernDarkColors.textPrimary,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontFamily: 'SF Pro Text',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: ModernDarkColors.card,
    selectedItemColor: ModernDarkColors.primary,
    unselectedItemColor: ModernDarkColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: ModernDarkColors.primary,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: CircleBorder(),
  ),
  dividerTheme: const DividerThemeData(
    color: ModernDarkColors.divider,
    thickness: 0.5,
    space: 1,
  ),
);
