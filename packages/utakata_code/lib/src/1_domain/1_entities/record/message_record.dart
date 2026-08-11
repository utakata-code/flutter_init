/// クライアントとの送受信**原文**の1件(v1.6.0)。
///
/// [LogEntry](log_entry.dart)が「人間が要約・整理した会話ログ」なのに対し、
/// こちらは「実際に送受信した文面そのもの」を保持する一次証跡。
/// 保存先は `doc/records/messages/YYYY-MM.jsonl`(追記専用)。
///
/// 原文性を守るため、取り込み時の秘匿マスク([REDACTED] 置換)は**行わない**。
/// 秘匿が必要な案件は `records.agent_read` と `.gitignore` で制御する。
library;

enum MessageDirection {
  /// 先方 → 自分
  inbound,

  /// 自分 → 先方
  outbound,
}

final class MessageRecord {
  /// `MSGR-YYYYMMDD-NNN`(log の `MSG-` とは別系統)
  final String id;

  final MessageDirection direction;

  /// 送受信の日時(原文に記載の時刻。不明なら記録時刻 + [atApprox])
  final DateTime at;
  final bool atApprox;

  /// `coconala` / `mail` / `chatwork` / `line` など。自由文字列
  final String? channel;

  final String? from;
  final String? to;
  final String? subject;

  /// 原文そのまま(無加工)
  final String body;

  /// プロジェクト相対パスの添付ファイル
  final List<String> attachments;

  final String? thread;

  /// 取り込み元での ID。再取り込み時の重複排除キー
  final String? externalId;

  /// 要約ログ([LogEntry.id])への紐付け
  final String? logRef;

  /// 合意([Agreement] の id)への紐付け
  final String? agreementRef;

  final DateTime recordedAt;

  /// 記録者。`agent:` 始まりならエージェントによる記録(ActorResolver 参照)
  final String recordedBy;

  const MessageRecord({
    required this.id,
    required this.direction,
    required this.at,
    this.atApprox = false,
    this.channel,
    this.from,
    this.to,
    this.subject,
    required this.body,
    this.attachments = const [],
    this.thread,
    this.externalId,
    this.logRef,
    this.agreementRef,
    required this.recordedAt,
    required this.recordedBy,
  });

  MessageRecord copyWith({String? logRef, String? agreementRef}) =>
      MessageRecord(
        id: id,
        direction: direction,
        at: at,
        atApprox: atApprox,
        channel: channel,
        from: from,
        to: to,
        subject: subject,
        body: body,
        attachments: attachments,
        thread: thread,
        externalId: externalId,
        logRef: logRef ?? this.logRef,
        agreementRef: agreementRef ?? this.agreementRef,
        recordedAt: recordedAt,
        recordedBy: recordedBy,
      );

  static MessageDirection directionFromString(String raw) {
    switch (raw) {
      case 'inbound':
      case 'in':
        return MessageDirection.inbound;
      case 'outbound':
      case 'out':
        return MessageDirection.outbound;
      default:
        throw ArgumentError('Unknown direction: $raw (inbound|outbound)');
    }
  }

  static String directionToString(MessageDirection direction) =>
      direction == MessageDirection.inbound ? 'inbound' : 'outbound';

  /// [externalId] が無い取り込み元のための重複判定キー。
  /// 同一 direction・同一時刻・同一本文なら同じメッセージとみなす。
  String get dedupeKey {
    final normalized = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    return '${directionToString(direction)}|'
        '${at.toIso8601String()}|'
        '${_fnv1a(normalized)}';
  }

  /// 依存を増やさないための FNV-1a 64bit(重複判定のみに使う)。
  static String _fnv1a(String input) {
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
