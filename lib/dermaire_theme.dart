import 'package:flutter/material.dart';

abstract final class DermaireColors {
  static const background = Color(0xFFF6E6D8);
  static const caramel = Color(0xFFD4B08A);
  static const deep = Color(0xFF8B5E3C);
  static const ink = Color(0xFF5A3A2F);
  static const card = Color(0xFFFFFDF9);
  static const paper = Color(0xFFFBF2E8);
  static const line = Color(0x245A3A2F);
  static const safe = Color(0xFF6E8F6C);
  static const conflict = Color(0xFFB0503A);
  static const unknown = Color(0xFFC69A45);
  static const safeBackground = Color(0xFFEAF0E6);
  static const conflictBackground = Color(0xFFF6E3DD);
  static const unknownBackground = Color(0xFFF5EBD6);
  static const darkBackground = Color(0xFF1D1411);
  static const darkSurface = Color(0xFF2B1E19);
  static const darkPaper = Color(0xFF382820);
  static const darkInk = Color(0xFFF8EDE4);
}

abstract final class DermaireTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final foreground = isDark ? DermaireColors.darkInk : DermaireColors.ink;
    final surface = isDark ? DermaireColors.darkSurface : DermaireColors.card;
    final background = isDark
        ? DermaireColors.darkBackground
        : DermaireColors.card;
    final body = TextStyle(
      fontFamily: 'Karla',
      color: foreground,
      height: 1.35,
    );
    final display = TextStyle(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w600,
      color: foreground,
      height: 1.15,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DermaireColors.deep,
        brightness: brightness,
        primary: isDark ? DermaireColors.caramel : DermaireColors.deep,
        surface: surface,
        onSurface: foreground,
        error: DermaireColors.conflict,
      ),
      textTheme: TextTheme(
        displayLarge: display,
        displayMedium: display,
        headlineLarge: display,
        headlineMedium: display,
        headlineSmall: display,
        titleLarge: display,
        titleMedium: body,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: body,
        labelLarge: body,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: foreground,
        titleTextStyle: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: isDark
              ? DermaireColors.caramel
              : DermaireColors.deep,
          foregroundColor: isDark
              ? DermaireColors.darkBackground
              : Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: isDark
              ? DermaireColors.caramel
              : DermaireColors.deep,
          side: const BorderSide(color: DermaireColors.caramel, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: foreground.withValues(alpha: .16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: foreground.withValues(alpha: .16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? DermaireColors.caramel : DermaireColors.deep,
            width: 1.5,
          ),
        ),
      ),
      dividerColor: foreground.withValues(alpha: .14),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? DermaireColors.darkInk : DermaireColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Karla',
          color: isDark ? DermaireColors.darkBackground : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
