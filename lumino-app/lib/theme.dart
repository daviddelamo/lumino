import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuminoTheme {
  static const primaryColor = Color(0xFFE8823A);
  static const accentColor = Color(0xFFF7C59F);
  static const supportingGreen = Color(0xFFA8D5BA);
  static const backgroundWarm = Color(0xFFFFF8F2);

  static const _bgDark = Color(0xFF1C120C);
  static const _surfaceDark = Color(0xFF2A1C12);
  static const _onSurfaceDark = Color(0xFFF5ECE0);
  static const _onSurfaceVariantDark = Color(0xFFB89878);
  static const _surfaceLight = Color(0xFFFFF0E6);

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _bgDark : backgroundWarm;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _surfaceDark : _surfaceLight;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _onSurfaceDark
          : const Color(0xFF3A2A1A);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _onSurfaceVariantDark
          : const Color(0xFFA08070);

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A2A1A)
          : const Color(0xFFEDD8C4);

  static TextTheme _buildTextTheme({required bool dark}) {
    final base = dark ? const Color(0xFFF5ECE0) : const Color(0xFF3A2A1A);
    final muted = dark ? const Color(0xFFB89878) : const Color(0xFFA08070);
    return GoogleFonts.figtreeTextTheme().copyWith(
      displayLarge: GoogleFonts.spectral(
          fontSize: 56, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.5),
      displayMedium: GoogleFonts.spectral(
          fontSize: 40, fontWeight: FontWeight.w700, color: base),
      displaySmall: GoogleFonts.spectral(
          fontSize: 34, fontWeight: FontWeight.w700, color: base),
      headlineLarge: GoogleFonts.spectral(
          fontSize: 28, fontWeight: FontWeight.w700, color: base),
      headlineMedium: GoogleFonts.spectral(
          fontSize: 22, fontWeight: FontWeight.w600, color: base),
      headlineSmall: GoogleFonts.spectral(
          fontSize: 18, fontWeight: FontWeight.w600, color: base),
      titleLarge:
          GoogleFonts.figtree(fontSize: 17, fontWeight: FontWeight.w600, color: base),
      titleMedium:
          GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: base),
      titleSmall:
          GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w600, color: base),
      bodyLarge: GoogleFonts.figtree(fontSize: 16, color: base),
      bodyMedium: GoogleFonts.figtree(fontSize: 14, color: base),
      bodySmall: GoogleFonts.figtree(fontSize: 12, color: muted),
      labelLarge:
          GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w500, color: base),
      labelMedium:
          GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
      labelSmall:
          GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w500, color: muted),
    );
  }

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          surface: backgroundWarm,
        ),
        scaffoldBackgroundColor: backgroundWarm,
        textTheme: _buildTextTheme(dark: false),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: _surfaceLight,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEDD8C4),
          thickness: 1,
          space: 0,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: accentColor,
          onSecondary: Color(0xFF3A2A1A),
          error: Color(0xFFEF9A9A),
          onError: Colors.black,
          surface: _surfaceDark,
          onSurface: _onSurfaceDark,
          onSurfaceVariant: _onSurfaceVariantDark,
          outline: Color(0xFF5A3E2A),
          outlineVariant: Color(0xFF3A2A1A),
          inverseSurface: _onSurfaceDark,
          onInverseSurface: _bgDark,
          inversePrimary: primaryColor,
          surfaceContainerHighest: Color(0xFF3A2A1A),
        ),
        scaffoldBackgroundColor: _bgDark,
        textTheme: _buildTextTheme(dark: true),
        appBarTheme:
            const AppBarTheme(backgroundColor: _bgDark, foregroundColor: _onSurfaceDark),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: _surfaceDark,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surfaceDark,
          indicatorColor: primaryColor.withValues(alpha: 0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryColor);
            }
            return const IconThemeData(color: _onSurfaceVariantDark);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.figtree(
                  color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return GoogleFonts.figtree(color: _onSurfaceVariantDark, fontSize: 12);
          }),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _surfaceDark,
          selectedItemColor: primaryColor,
          unselectedItemColor: _onSurfaceVariantDark,
        ),
        dividerColor: const Color(0xFF3A2A1A),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? primaryColor : _onSurfaceVariantDark),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? primaryColor.withValues(alpha: 0.4)
                  : const Color(0xFF3A2A1A)),
        ),
      );
}
