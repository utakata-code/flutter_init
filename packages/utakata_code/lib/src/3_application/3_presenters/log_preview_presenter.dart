import '../../1_domain/1_entities/record/log_entry.dart';

/// 会話ログの1日分を Markdown プレビューへ変換する。
///
/// 出力は「自動生成・編集禁止」ヘッダ + メッセージごとの見出し +
/// ID アンカー(出典参照はこの ID を使う。仕様書 §7.1)。
abstract final class LogPreviewPresenter {
  static String renderDay(DateTime date, List<LogEntry> entries) {
    final buffer = StringBuffer();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    buffer.writeln('> ⚠️ 自動生成 — 編集しないでください。`utakata log render` で再生成されます。');
    buffer.writeln();
    buffer.writeln('# $dateStr の会話ログ');
    buffer.writeln();

    for (final entry in entries) {
      final time = '${entry.at.hour.toString().padLeft(2, '0')}:'
          '${entry.at.minute.toString().padLeft(2, '0')}';
      final displayName = entry.name ?? LogEntry.speakerToString(entry.speaker);

      if (entry.kind == LogEntryKind.draft) {
        buffer.writeln('#### 【回答案】(未送信) $time $displayName');
      } else {
        buffer.writeln('### $time $displayName');
      }
      buffer.writeln('<!-- id: ${entry.id}${entry.thread != null ? ' thread: ${entry.thread}' : ''} -->');
      buffer.writeln();
      buffer.writeln(entry.body);

      if (entry.sentAs != null) {
        buffer.writeln();
        buffer.writeln('_(→ ${entry.sentAs} として送信)_');
      }
      if (entry.readAt != null) {
        final r = entry.readAt!;
        buffer.writeln();
        buffer.writeln(
            '_既読 ${r.month}/${r.day} ${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}_');
      }
      for (final attachment in entry.attachments) {
        buffer.writeln('![$attachment](../records/log/attachments/$attachment)');
      }
      if (entry.tags.isNotEmpty) {
        buffer.writeln(entry.tags.map((t) => '`#$t`').join(' '));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
