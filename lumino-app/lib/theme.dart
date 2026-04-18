import 'package:flutter/material.dart';

class LuminoTheme {
  static const primaryColor = Color(0xFFE8823A);
  static const accentColor = Color(0xFFF7C59F);
  static const supportingGreen = Color(0xFFA8D5BA);
  static const backgroundWarm = Color(0xFFFFF8F2);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: backgroundWarm,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
    ),
    cardTheme: const CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}
