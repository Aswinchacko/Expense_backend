import 'package:flutter/material.dart';

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

/// Cached text styles — avoid allocating on every build.
abstract final class FolioText {
  static const amount48 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: FolioColors.foreground,
    letterSpacing: -1,
  );

  static const amount44 = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: FolioColors.foreground,
    letterSpacing: -1,
  );

  static const amount28 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: FolioColors.foreground,
    letterSpacing: -0.5,
  );

  static const label16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: FolioColors.foreground,
  );

  static const label15 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: FolioColors.foreground,
  );

  static const label14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: FolioColors.foreground,
  );

  static const label13 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: FolioColors.foreground,
  );

  static const label13Bold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: FolioColors.foreground,
    decoration: TextDecoration.underline,
    decorationThickness: 2,
  );

  static const meta12 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0x80000000),
  );
}

class FolioTheme {
  static ThemeData get light {
    return ThemeData(
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
    if (size == 48) return FolioText.amount48;
    if (size == 44) return FolioText.amount44;
    if (size == 28) return FolioText.amount28;
    return FolioText.amount48.copyWith(fontSize: size);
  }

  static TextStyle labelStyle(BuildContext context, {double size = 14}) {
    if (size == 16) return FolioText.label16;
    if (size == 15) return FolioText.label15;
    if (size == 14) return FolioText.label14;
    if (size == 13) return FolioText.label13;
    return FolioText.label14.copyWith(fontSize: size);
  }

  static TextStyle metaStyle(BuildContext context, {double size = 12}) {
    return size == 12 ? FolioText.meta12 : FolioText.meta12.copyWith(fontSize: size);
  }
}
