import '../1_entities/record/message_record.dart';

/// 送受信原文(`doc/records/messages/YYYY-MM.jsonl`)の読み書きを行う
/// リポジトリのインターフェース(v1.6.0)。
///
/// **追記専用**。原文は一次証跡なので、既存レコードの書き換え API は
/// 持たない(唯一の例外は [link] — 後から要約・合意への参照を足す操作で、
/// 本文には触れない)。
abstract interface class MessageRepository {
  /// 1件追記する。ID は呼び出し前に採番済みであること([nextId] 参照)。
  Future<void> append(String projectDir, MessageRecord record);

  /// 指定日の既存レコード数から次の連番 ID(`MSGR-YYYYMMDD-NNN`)を採番する。
  Future<String> nextId(String projectDir, DateTime at);

  /// フィルタ付きで検索する(null のフィルタは無視)。
  Future<List<MessageRecord>> query(
    String projectDir, {
    MessageDirection? direction,
    String? channel,
    String? thread,
    String? month, // 'YYYY-MM'
    String? id,
  });

  /// 全件を月別ファイル横断で読み出す(render / 重複判定用)。
  Future<List<MessageRecord>> readAll(String projectDir);

  /// [externalId] または [dedupeKey] に一致する既存レコードがあるか。
  Future<bool> existsDuplicate(
    String projectDir, {
    String? externalId,
    String? dedupeKey,
  });

  /// 既存レコードに要約ログ・合意への参照を付ける(本文は変更しない)。
  /// 対象が見つからなければ false。
  Future<bool> link(
    String projectDir,
    String id, {
    String? logRef,
    String? agreementRef,
  });
}
