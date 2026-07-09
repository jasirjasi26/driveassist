import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Colors - HSL Tailored & Neon Accent Palettes
  static const Color spaceCadet = Color(0xFF0D111D); // Deep Space Background
  static const Color darkBlueGray = Color(0xFF1E2530); // Mid-layer cards
  static const Color electricTeal = Color(0xFF00E5FF); // Safe state / Main Action
  static const Color neonCrimson = Color(0xFFFF2A6D); // Unsafe state / Alert Y
  static const Color warningOrange = Color(0xFFFF8C00); // Warning/Caution
  static const Color brightGreen = Color(0xFF39FF14); // HUD neon green / Windshield mode
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color translucentWhite = Color(0x1FFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Gradient definitions
  static const LinearGradient bgGradient = LinearGradient(
    colors: [spaceCadet, Color(0xFF0A0C14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [electricTeal, Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [neonCrimson, Color(0xFFFF0055)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningOrange, Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // HUD Theme
  static ThemeData get hudTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: brightGreen,
      colorScheme: const ColorScheme.dark(
        primary: brightGreen,
        background: Colors.black,
        surface: Colors.black,
        error: neonCrimson,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: const TextStyle(color: brightGreen, fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(color: brightGreen, fontWeight: FontWeight.bold),
        displaySmall: const TextStyle(color: brightGreen, fontWeight: FontWeight.bold),
        headlineMedium: const TextStyle(color: brightGreen, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(color: brightGreen, fontSize: 18),
        bodyMedium: const TextStyle(color: brightGreen, fontSize: 16),
      ),
    );
  }

  // Active Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spaceCadet,
      primaryColor: electricTeal,
      colorScheme: const ColorScheme.dark(
        primary: electricTeal,
        secondary: Color(0xFF0D9488),
        background: spaceCadet,
        surface: darkBlueGray,
        error: neonCrimson,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: pureWhite, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.outfit(color: pureWhite, fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.outfit(color: pureWhite, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.outfit(color: pureWhite, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(color: pureWhite, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: pureWhite.withOpacity(0.9)),
        bodyMedium: GoogleFonts.outfit(color: pureWhite.withOpacity(0.7)),
      ),
      cardTheme: const CardThemeData(
        color: Color(0x661E2530), // darkBlueGray with opacity
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: glassBorder, width: 0.5),
        ),
      ),
    );
  }
}
