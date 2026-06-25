import 'package:flutter/material.dart';

/// utakata studio のダークテーマ定義
///
/// 洗練されたダークテーマ。彩度を抑えたアクセントカラーと
/// 落ち着いた背景色で、長時間の作業でも目に優しいデザインシステム。
class StudioTheme {
  StudioTheme._();

  // ── ベースカラー ──
  static const darkBg = Color(0xFF111318);
  static const sidebarBg = Color(0xFF181B21);
  static const surfaceBg = Color(0xFF1E2128);
  static const editorBg = Color(0xFF111318);

  // ── ボーダー ──
  static const borderColor = Color(0xFF2A2F38);
  static const borderLight = Color(0xFF353B45);

  // ── テキスト ──
  static const textPrimary = Color(0xFFE0E4EA);
  static const textSecondary = Color(0xFF8B919A);
  static const textMuted = Color(0xFF5C6370);

  // ── アクセント（落ち着いたトーン） ──
  static const accentCyan = Color(0xFF6CB6D1);
  static const accentGreen = Color(0xFF5CA97C);
  static const accentRed = Color(0xFFD16B6B);
  static const accentYellow = Color(0xFFC4A45A);
  static const accentPurple = Color(0xFF9B8EC4);

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

