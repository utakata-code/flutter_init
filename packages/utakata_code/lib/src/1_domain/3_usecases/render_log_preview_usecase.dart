import 'package:path/path.dart' as p;

import '../1_entities/record/log_entry.dart';
import '../2_repositories/conversation_log_repository.dart';

/// `utakata log render` — 会話ログの .md プレビューを日付別に再生成する。
///
/// Markdown への変換自体はアプリケーション層(presenter)の責務なので、
/// [renderDay] として関数注入する(domain はレンダリング詳細を知らない)。
class RenderLogPreviewUsecase {
  final ConversationLogRepository _repo;
  final String Function(DateTime date, List<LogEntry> entries) _renderDay;
  final Future<void> Function(String path, String content) _writeFile;

  const RenderLogPreviewUsecase({
    required ConversationLogRepository repo,
    required String Function(DateTime date, List<LogEntry> entries) renderDay,
    required Future<void> Function(String path, String content) writeFile,
  })  : _repo = repo,
        _renderDay = renderDay,
        _writeFile = writeFile;

  /// 再生成した日付の一覧を返す。
  Future<List<DateTime>> execute(String projectDir) async {
    final all = await _repo.readAll(projectDir);
    final byDate = <DateTime, List<LogEntry>>{};
    for (final entry in all) {
      final dateKey = DateTime(entry.at.year, entry.at.month, entry.at.day);
      byDate.putIfAbsent(dateKey, () => []).add(entry);
    }

    final dates = byDate.keys.toList()..sort();
    for (final date in dates) {
      final entries = byDate[date]!;
      final markdown = _renderDay(date, entries);
      final fileName = '${date.toIso8601String().substring(0, 10)}.md';
      await _writeFile(p.join(projectDir, 'doc', 'preview', 'log_$fileName'), markdown);
    }
    return dates;
  }
}
