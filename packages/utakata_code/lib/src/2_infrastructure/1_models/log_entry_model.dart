import '../../1_domain/1_entities/record/log_entry.dart';

/// JSONL の1行(Map)⇔ [LogEntry] の変換を担う DTO。
abstract final class LogEntryModel {
  static LogEntry fromMap(Map<String, dynamic> map) => LogEntry(
        id: map['id'] as String,
        at: DateTime.parse(map['at'] as String),
        atApprox: (map['at_approx'] as bool?) ?? false,
        speaker: LogEntry.speakerFromString(map['speaker'] as String),
        name: map['name'] as String?,
        kind: LogEntry.kindFromString((map['kind'] as String?) ?? 'message'),
        body: map['body'] as String,
        channel: map['channel'] as String?,
        replyTo: map['reply_to'] as String?,
        thread: map['thread'] as String?,
        tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        attachments:
            (map['attachments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        readAt: map['read_at'] != null ? DateTime.parse(map['read_at'] as String) : null,
        sentAs: map['sent_as'] as String?,
        recordedAt: DateTime.parse(map['recorded_at'] as String),
        recordedBy: map['recorded_by'] as String,
      );

  static Map<String, dynamic> toMap(LogEntry entry) => {
        'id': entry.id,
        'at': entry.at.toIso8601String(),
        if (entry.atApprox) 'at_approx': true,
        'speaker': LogEntry.speakerToString(entry.speaker),
        if (entry.name != null) 'name': entry.name,
        'kind': LogEntry.kindToString(entry.kind),
        'body': entry.body,
        if (entry.channel != null) 'channel': entry.channel,
        if (entry.replyTo != null) 'reply_to': entry.replyTo,
        if (entry.thread != null) 'thread': entry.thread,
        if (entry.tags.isNotEmpty) 'tags': entry.tags,
        if (entry.attachments.isNotEmpty) 'attachments': entry.attachments,
        if (entry.readAt != null) 'read_at': entry.readAt!.toIso8601String(),
        if (entry.sentAs != null) 'sent_as': entry.sentAs,
        'recorded_at': entry.recordedAt.toIso8601String(),
        'recorded_by': entry.recordedBy,
      };
}
