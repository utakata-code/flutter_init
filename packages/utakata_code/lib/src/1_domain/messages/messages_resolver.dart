import 'dart:io';

import 'cli_messages.dart';
import 'en_messages.dart';
import 'ja_messages.dart';

/// 言語解決ファクトリ
///
/// 環境変数を読んで適切な CliMessages 実装を返す。
/// 優先順位:
///   1. UTAKATA_LANG = 'ja' | 'en'
///   2. システムの LANG 環境変数から推定（例: ja_JP.UTF-8 → 'ja'）
///   3. フォールバック: 'en'
abstract final class MessagesResolver {
  static CliMessages resolve() {
    final lang = _detectLang();
    return switch (lang) {
      'ja' => const JaMessages(),
      _    => const EnMessages(),
    };
  }

  static String _detectLang() {
    // 1. 明示的な指定
    final explicit = Platform.environment['UTAKATA_LANG'];
    if (explicit != null && explicit.isNotEmpty) return explicit.toLowerCase();

    // 2. システムの LANG 環境変数から推定
    final systemLang = Platform.environment['LANG'] ?? '';
    if (systemLang.startsWith('ja')) return 'ja';

    return 'en';
  }
}
