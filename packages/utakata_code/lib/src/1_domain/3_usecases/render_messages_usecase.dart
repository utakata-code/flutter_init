import 'package:path/path.dart' as p;

import '../1_entities/record/message_record.dart';
import '../2_repositories/message_repository.dart';

/// `utakata message render` — 送受信原文の .md プレビューを月別に再生成する。
///
/// Markdown 化は presenter に委ねる(domain はレンダリング詳細を知らない)。
class RenderMessagesUsecase {
  final MessageRepository _repo;
  final String Function(String month, List<MessageRecord> records) _renderMonth;
  final Future<void> Function(String path, String content) _writeFile;

  const RenderMessagesUsecase({
    required MessageRepository repo,
    required String Function(String month, List<MessageRecord> records)
        renderMonth,
    required Future<void> Function(String path, String content) writeFile,
  })  : _repo = repo,
        _renderMonth = renderMonth,
        _writeFile = writeFile;

  /// 再生成した月(`YYYY-MM`)の一覧を返す。
  Future<List<String>> execute(String projectDir) async {
    final all = await _repo.readAll(projectDir);
    final byMonth = <String, List<MessageRecord>>{};
    for (final record in all) {
      final month = '${record.at.year.toString().padLeft(4, '0')}-'
          '${record.at.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(month, () => []).add(record);
    }

    final months = byMonth.keys.toList()..sort();
    for (final month in months) {
      await _writeFile(
        p.join(projectDir, 'doc', 'preview', 'messages', '$month.md'),
        _renderMonth(month, byMonth[month]!),
      );
    }
    return months;
  }
}
