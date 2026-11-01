import 'package:flutter/material.dart';

/// All the colours and shared styles live here in ONE place.
///
/// Why: if you ever want to change the accent colour, you change it here
/// instead of hunting through every screen.
class AppColors {
  // Private constructor: this class is only a holder for constants,
  // nobody should ever write `AppColors()`.
  AppColors._();

  static const Color accent = Color(0xFFFFD60A); // bright yellow
  static const Color ink = Color(0xFF0D0D0D); // near-black (text + borders)
  static const Color background = Color(0xFFF5F3EF); // off-white page colour
  static const Color surface = Color(0xFFFFFFFF); // white cards
  static const Color muted = Color(0xFF8A867E); // grey for disabled things
  static const Color danger = Color(0xFFE5484D); // red for cancel/delete
}

/// Shared "chunky border" used by nearly every card and button.
/// Making it a constant keeps the look consistent across screens.
const BorderSide kInkBorderSide = BorderSide(color: AppColors.ink, width: 2);

/// A hard (non-blurred) drop shadow. This gives the app its bold, sticker-like
/// look. `blurRadius: 0` is what makes the shadow a solid block instead of a
/// soft fade.
List<BoxShadow> inkShadow({double offset = 4}) => [
      BoxShadow(
        color: AppColors.ink,
        offset: Offset(offset, offset),
        blurRadius: 0,
      ),
    ];

/// Builds the app-wide [ThemeData].
///
/// A ThemeData is handed to `MaterialApp(theme: ...)` and every widget below
/// it can read these defaults, so we don't repeat colours on every widget.
ThemeData buildAppTheme() {
  // A ColorScheme is Material 3's palette. We seed it from our own colours.
  const colorScheme = ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: AppColors.accent,
    secondary: AppColors.accent,
    onSecondary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,

    // Default look for every AppBar in the app.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    ),

    // Default text styling: tight, heavy headings.
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
        letterSpacing: -1,
        height: 1.1,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.ink,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: 0.4,
      ),
    ),

    // Make the built-in date picker match our palette.
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.background,
      headerBackgroundColor: AppColors.accent,
      headerForegroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
