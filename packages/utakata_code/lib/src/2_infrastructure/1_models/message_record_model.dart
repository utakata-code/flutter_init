import '../../1_domain/1_entities/record/message_record.dart';

/// JSONL の1行(Map)⇔ [MessageRecord] の変換を担う DTO。
abstract final class MessageRecordModel {
  static MessageRecord fromMap(Map<String, dynamic> map) => MessageRecord(
        id: map['id'] as String,
        direction:
            MessageRecord.directionFromString(map['direction'] as String),
        at: DateTime.parse(map['at'] as String),
        atApprox: (map['at_approx'] as bool?) ?? false,
        channel: map['channel'] as String?,
        from: map['from'] as String?,
        to: map['to'] as String?,
        subject: map['subject'] as String?,
        body: map['body'] as String,
        attachments:
            (map['attachments'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        thread: map['thread'] as String?,
        externalId: map['external_id'] as String?,
        logRef: map['log_ref'] as String?,
        agreementRef: map['agreement_ref'] as String?,
        recordedAt: DateTime.parse(map['recorded_at'] as String),
        recordedBy: map['recorded_by'] as String,
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
