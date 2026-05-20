import 'package:flutter/material.dart';

/// utakata studio 全体で統一するプレミアムダークテーマ
class StudioTheme {
  StudioTheme._();

  // ───── カラーパレット (HSLベースの調和色) ─────
  static const darkBg = Color(0xFF0C0E17);
  static const sidebarBg = Color(0xFF121422);
  static const editorBg = Color(0xFF181A2C);
  static const surfaceBg = Color(0xFF1E2235);
  static const borderColor = Color(0xFF22263F);
  static const borderLight = Color(0xFF2D334F);

  static const accentCyan = Color(0xFF00F0FF);
  static const accentGreen = Color(0xFF00FF88);
  static const accentRed = Color(0xFFFF496C);
  static const accentYellow = Color(0xFFFFD666);
  static const accentPurple = Color(0xFFA78BFA);

  static const textPrimary = Color(0xFFE8ECF4);
  static const textSecondary = Color(0xFF9DA5B4);
  static const textMuted = Color(0xFF565F89);

  // ───── ThemeData ─────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: accentCyan,
          secondary: accentPurple,
          surface: surfaceBg,
          error: accentRed,
          onPrimary: darkBg,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Segoe UI',
            color: textSecondary,
            fontSize: 13,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Segoe UI',
            color: textMuted,
            fontSize: 11,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 10,
            color: textMuted,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: borderColor,
          thickness: 1,
          space: 1,
        ),
        iconTheme: const IconThemeData(
          color: textSecondary,
          size: 20,
        ),
      );
}
