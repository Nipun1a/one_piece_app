import 'package:flutter/material.dart';

/// Material 3 theme for Grand Line Store — One Piece / nautical aesthetic.
class AppTheme {
  AppTheme._(); // prevent instantiation

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1565C0); // deep ocean blue
  static const Color _secondary = Color(0xFFFFC107); // golden yellow (Straw Hat)
  static const Color _error = Color(0xFFB00020); // classic Material red

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      error: _error,
      surface: const Color(0xFFF5F5F5), // light grey surface
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: Colors.white, // text + icons
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        elevation: 2,
        centerTitle: false,
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Chip (category chips) ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: _primary,
        secondarySelectedColor: _primary,
        disabledColor: Colors.grey.shade200,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _primary.withAlpha(77)),
        ),
        showCheckmark: false,
      ),

      // ── Input decoration (search field, form fields) ────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── FloatingActionButton ─────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondary,
        foregroundColor: Colors.black87,
      ),
    );
  }
}
