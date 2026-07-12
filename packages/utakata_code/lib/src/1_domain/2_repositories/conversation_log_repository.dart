import '../1_entities/record/log_entry.dart';

/// お客様会話ログ(`doc/records/log/YYYY-MM.jsonl`)の読み書きを行う
/// リポジトリのインターフェース。
///
/// 追記専用。書き込みは人間が `utakata log add` を実行した時のみ
/// (AI は読み取り専用。仕様書 §7.1・P8)。
abstract interface class ConversationLogRepository {
  /// 1件追記する。ID は呼び出し前に採番済みであること([nextId] 参照)。
  Future<void> append(String projectDir, LogEntry entry);

  /// 指定日の既存エントリ数から次の連番 ID を採番する。
  Future<String> nextId(String projectDir, DateTime at);

  /// フィルタ付きで検索する(null のフィルタは無視)。
  Future<List<LogEntry>> query(
    String projectDir, {
    DateTime? date,
    String? thread,
    String? tag,
    String? id,
  });

  /// 全件を月別ファイル横断で読み出す(render/check 用)。
  Future<List<LogEntry>> readAll(String projectDir);

  /// ID の重複有無を確認する。
  Future<bool> exists(String projectDir, String id);
}
