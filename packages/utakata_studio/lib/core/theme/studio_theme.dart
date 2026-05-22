import 'package:flutter/material.dart';

/// utakata studio のダークテーマ定義
///
/// プレミアム感のあるダークテーマ。グラデーション・グラスモーフィズム・
/// サイアン系アクセントカラーを基調とした統一デザインシステム。
class StudioTheme {
  StudioTheme._();

  // ── ベースカラー ──
  static const darkBg = Color(0xFF0D1117);
  static const sidebarBg = Color(0xFF161B22);
  static const surfaceBg = Color(0xFF1C2128);
  static const editorBg = Color(0xFF0D1117);

  // ── ボーダー ──
  static const borderColor = Color(0xFF30363D);
  static const borderLight = Color(0xFF3D444D);

  // ── テキスト ──
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF656D76);

  // ── アクセント ──
  static const accentCyan = Color(0xFF58D4F0);
  static const accentGreen = Color(0xFF3FB950);
  static const accentRed = Color(0xFFF85149);
  static const accentYellow = Color(0xFFD29922);
  static const accentPurple = Color(0xFFBC8CFF);

  /// ダークテーマ
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        canvasColor: sidebarBg,
        dividerColor: borderColor,
        colorScheme: const ColorScheme.dark(
          primary: accentCyan,
          secondary: accentPurple,
          surface: surfaceBg,
          error: accentRed,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          bodySmall: TextStyle(color: textMuted, fontSize: 12),
          labelSmall: TextStyle(
            color: textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: borderColor,
          thickness: 1,
          space: 0,
        ),
        iconTheme: const IconThemeData(color: textSecondary, size: 20),
      );
}
