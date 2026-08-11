import '../../1_domain/1_entities/record/message_record.dart';
import '../../1_domain/services/date_resolver.dart';

/// JSONL の1行(Map)⇔ [MessageRecord] の変換を担う DTO。
abstract final class MessageRecordModel {
  /// 1行を [MessageRecord] へ変換する。
  ///
  /// 手編集や別ツールの出力で型が想定と違う行があっても例外で全体を
  /// 落とさないよう、必須項目が読めない場合は null を返す(呼び出し側が
  /// スキップして警告する)。
  static MessageRecord? tryFromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final direction = map['direction'];
    final body = map['body'];
    final at = map['at'];
    if (id is! String || direction is! String || body is! String) return null;
    if (at is! String) return null;

    final MessageRecord record;
    try {
      record = fromMap(map);
    } catch (_) {
      return null;
    }
    return record;
  }

  static MessageRecord fromMap(Map<String, dynamic> map) => MessageRecord(
        id: map['id'] as String,
        direction:
            MessageRecord.directionFromString(map['direction'] as String),
        at: DateResolver.toLocal(DateTime.parse(map['at'] as String)),
        atApprox: (map['at_approx'] as bool?) ?? false,
        channel: map['channel']?.toString(),
        from: map['from']?.toString(),
        to: map['to']?.toString(),
        subject: map['subject']?.toString(),
        body: map['body'] as String,
        attachments:
            (map['attachments'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        thread: map['thread']?.toString(),
        externalId: map['external_id']?.toString(),
        logRef: map['log_ref']?.toString(),
        agreementRef: map['agreement_ref']?.toString(),
        recordedAt: map['recorded_at'] is String
            ? DateResolver.toLocal(DateTime.parse(map['recorded_at'] as String))
            : DateResolver.toLocal(DateTime.parse(map['at'] as String)),
        recordedBy: map['recorded_by']?.toString() ?? 'unknown',
      );

  static Map<String, dynamic> toMap(MessageRecord record) => {
        'id': record.id,
        'direction': MessageRecord.directionToString(record.direction),
        'at': record.at.toIso8601String(),
        if (record.atApprox) 'at_approx': true,
        if (record.channel != null) 'channel': record.channel,
        if (record.from != null) 'from': record.from,
        if (record.to != null) 'to': record.to,
        if (record.subject != null) 'subject': record.subject,
        'body': record.body,
        if (record.attachments.isNotEmpty) 'attachments': record.attachments,
        if (record.thread != null) 'thread': record.thread,
        if (record.externalId != null) 'external_id': record.externalId,
        if (record.logRef != null) 'log_ref': record.logRef,
        if (record.agreementRef != null) 'agreement_ref': record.agreementRef,
        'recorded_at': record.recordedAt.toIso8601String(),
        'recorded_by': record.recordedBy,
      };
}
