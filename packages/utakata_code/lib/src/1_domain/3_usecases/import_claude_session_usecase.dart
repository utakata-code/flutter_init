import 'dart:convert';

/// 取り込み後の正規化エントリ(実装計画 S6)。
///
/// Claude Code 側の内部フォーマット変更から絶縁するため、生 JSON を
/// そのまま持たず {ts, role, text, session, seq} に正規化して保存する。
final class SessionEntry {
  final String ts;
  final String role; // user | assistant
  final String text;
  final String session;
  final int seq;

  const SessionEntry({
    required this.ts,
    required this.role,
    required this.text,
    required this.session,
    required this.seq,
  });

  Map<String, dynamic> toMap() =>
      {'ts': ts, 'role': role, 'text': text, 'session': session, 'seq': seq};
}

class SessionSummary {
  final String id;
  final String fileName;
  final String firstTs;
  final String excerpt;

  const SessionSummary({
    required this.id,
    required this.fileName,
    required this.firstTs,
    required this.excerpt,
  });
}

class ImportResult {
  final List<SessionEntry> entries;
  final int redactedCount;
  final int skippedLines;

  const ImportResult({
    required this.entries,
    required this.redactedCount,
    required this.skippedLines,
  });
}

/// `utakata log import claude-session` — Claude Code セッション生トランスクリプトの
/// 人間駆動取り込み(v1.0.0 ロードマップD確定版)。
///
/// - 既定では user 発言と assistant のテキスト応答のみ(thinking・tool_use・
///   tool_result・サブエージェントは除外)。[includeAll] で thinking も含める。
/// - 秘密情報らしい行は `[REDACTED]` に置換して件数を報告する(既定 on)。
/// - AI は `doc/records/**` に書けない(deny ルール)。このコマンドは人間が実行する。
class ImportClaudeSessionUsecase {
  static final _secretPatterns = <RegExp>[
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    RegExp(r'\bAKIA[0-9A-Z]{16}\b'), // AWS Access Key ID
    RegExp(r'\b(sk|pk|rk)-[A-Za-z0-9_\-]{20,}\b'), // APIキー形式(sk-...)
    RegExp(r'\bBearer\s+[A-Za-z0-9_\-\.=]{16,}', caseSensitive: false),
    RegExp(r'\b[A-Z][A-Z0-9_]*(KEY|TOKEN|SECRET|PASSWORD)[A-Z0-9_]*\s*=\s*\S+'),
    RegExp(r'\bghp_[A-Za-z0-9]{30,}\b'), // GitHub PAT
  ];

  const ImportClaudeSessionUsecase();

  /// Claude Code が使うプロジェクトディレクトリ名(パスの `/`・`_`・`.` を `-` へ)。
  static String projectKeyOf(String projectDir) =>
      projectDir.replaceAll(RegExp(r'[/_.]'), '-');

  /// トランスクリプト(JSONL 行)を正規化エントリへ変換する。純関数。
  static ImportResult parse(
    Iterable<String> lines, {
    required String sessionId,
    bool includeAll = false,
    bool redactSecrets = true,
  }) {
    final entries = <SessionEntry>[];
    var redacted = 0;
    var skipped = 0;
    var seq = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(line);
      } catch (_) {
        skipped++;
        continue;
      }
      if (decoded is! Map<String, dynamic>) {
        skipped++;
        continue;
      }
      final type = decoded['type'];
      if (type != 'user' && type != 'assistant') continue;
      if (decoded['isSidechain'] == true) continue; // サブエージェントは除外

      final message = decoded['message'];
      if (message is! Map) continue;
      final content = message['content'];

      final texts = <String>[];
      if (content is String) {
        texts.add(content);
      } else if (content is List) {
        for (final block in content.whereType<Map>()) {
          final blockType = block['type'];
          if (blockType == 'text') {
            texts.add(block['text']?.toString() ?? '');
          } else if (includeAll && blockType == 'thinking') {
            texts.add('[thinking] ${block['thinking'] ?? ''}');
          } else if (includeAll && blockType == 'tool_use') {
            texts.add('[tool_use] ${block['name'] ?? ''}');
          }
          // tool_result は --full でも本文が巨大なため除外する
        }
      }

      final text = texts.where((t) => t.trim().isNotEmpty).join('\n').trim();
      if (text.isEmpty) continue;

      var body = text;
      if (redactSecrets) {
        for (final pattern in _secretPatterns) {
          if (pattern.hasMatch(body)) {
            body = body.replaceAll(pattern, '[REDACTED]');
            redacted++;
          }
        }
      }

      entries.add(SessionEntry(
        ts: decoded['timestamp']?.toString() ?? '',
        role: type as String,
        text: body,
        session: sessionId,
        seq: seq++,
      ));
    }

    return ImportResult(
        entries: entries, redactedCount: redacted, skippedLines: skipped);
  }

  /// 正規化エントリを JSONL 化する。
  static String toJsonl(List<SessionEntry> entries) =>
      entries.map((e) => jsonEncode(e.toMap())).map((l) => '$l\n').join();

  /// 人間可読プレビュー(doc/preview/sessions/ 用)。
  static String toMarkdown(List<SessionEntry> entries, String sessionId) {
    final buffer = StringBuffer()
      ..writeln('# Claude Code セッション $sessionId')
      ..writeln()
      ..writeln('> `utakata log import claude-session` による取り込み。'
          '正本は doc/records/sessions/ の JSONL。')
      ..writeln();
    for (final e in entries) {
      final label = e.role == 'user' ? '👤 user' : '🤖 assistant';
      buffer
        ..writeln('## $label — ${e.ts}')
        ..writeln()
        ..writeln(e.text)
        ..writeln();
    }
    return buffer.toString();
  }
}
