import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class FolioColors {
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF000000);
  static const surfaceMuted = Color(0xFFF5F5F5);
  static const border = Color(0xFFE8E8E8);
  static const barTrack = Color(0xFFE8E8E8);
}

abstract final class FolioRadii {
  static const pill = 999.0;
  static const card = 24.0;
}

class FolioTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: FolioColors.background,
      colorScheme: const ColorScheme.light(
        primary: FolioColors.foreground,
        onPrimary: FolioColors.background,
        surface: FolioColors.background,
        onSurface: FolioColors.foreground,
      ),
      dividerColor: FolioColors.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: FolioColors.foreground,
        displayColor: FolioColors.foreground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FolioColors.background,
        foregroundColor: FolioColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FolioColors.foreground,
          foregroundColor: FolioColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FolioRadii.pill),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FolioColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FolioRadii.card),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  static TextStyle amountStyle(BuildContext context, {double size = 48}) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: FolioColors.foreground,
      letterSpacing: -1,
    );
  }

  static TextStyle labelStyle(BuildContext context, {double size = 14}) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: FolioColors.foreground,
    );
  }

  static TextStyle metaStyle(BuildContext context, {double size = 12}) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: FolioColors.foreground.withValues(alpha: 0.5),
    );
  }
}
