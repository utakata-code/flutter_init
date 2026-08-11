import 'dart:convert';

import '../1_entities/record/message_record.dart';
import '../2_repositories/message_repository.dart';

/// 取り込み1件分の結果。
final class ImportedMessage {
  final MessageRecord record;

  /// 既存と重複していて取り込まなかったか
  final bool skipped;

  const ImportedMessage({required this.record, required this.skipped});
}

/// `utakata message import` — 既存のやり取りを一括で取り込むユースケース。
///
/// 重複排除は `external_id`(あれば)→ [MessageRecord.dedupeKey] の順。
/// 同じファイルを2回流しても増えないので、エクスポートを繰り返す運用に耐える。
class ImportMessagesUsecase {
  final MessageRepository _repo;

  const ImportMessagesUsecase({required MessageRepository repo}) : _repo = repo;

  /// [format]: `jsonl` | `md`
  Future<List<ImportedMessage>> execute(
    String projectDir, {
    required String content,
    required String format,
    required DateTime now,
    required String recordedBy,
    String? defaultChannel,
    bool dryRun = false,
  }) async {
    final parsed = switch (format) {
      'jsonl' => parseJsonl(content),
      'md' => parseMarkdown(content),
      _ => throw ArgumentError('Unknown format: $format (jsonl|md)'),
    };

    final results = <ImportedMessage>[];
    // 同一ファイル内の重複も弾くため、取り込み済みキーを持ち回る
    final seenKeys = <String>{};

    for (final draft in parsed) {
      final at = draft.at ?? now;
      final provisional = MessageRecord(
        id: '(pending)',
        direction: draft.direction,
        at: at,
        atApprox: draft.at == null,
        channel: draft.channel ?? defaultChannel,
        from: draft.from,
        to: draft.to,
        subject: draft.subject,
        body: draft.body,
        thread: draft.thread,
        externalId: draft.externalId,
        recordedAt: now,
        recordedBy: recordedBy,
      );

      final key = draft.externalId ?? provisional.dedupeKey;
      final duplicated = seenKeys.contains(key) ||
          await _repo.existsDuplicate(
            projectDir,
            externalId: draft.externalId,
            dedupeKey: provisional.dedupeKey,
          );
      if (duplicated) {
        results.add(ImportedMessage(record: provisional, skipped: true));
        continue;
      }
      seenKeys.add(key);

      final id = await _repo.nextId(projectDir, at);
      final record = MessageRecord(
        id: id,
        direction: provisional.direction,
        at: provisional.at,
        atApprox: provisional.atApprox,
        channel: provisional.channel,
        from: provisional.from,
        to: provisional.to,
        subject: provisional.subject,
        body: provisional.body,
        thread: provisional.thread,
        externalId: provisional.externalId,
        recordedAt: now,
        recordedBy: recordedBy,
      );
      if (!dryRun) await _repo.append(projectDir, record);
      results.add(ImportedMessage(record: record, skipped: false));
    }

    return results;
  }

  /// JSONL(1行1メッセージ)。キーは `doc/records/messages/` と同じ。
  static List<MessageDraft> parseJsonl(String content) {
    final drafts = <MessageDraft>[];
    for (final line in const LineSplitter().convert(content)) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) continue;
      final direction = decoded['direction'];
      final body = decoded['body'];
      if (direction is! String || body is! String) continue;
      drafts.add(MessageDraft(
        direction: MessageRecord.directionFromString(direction),
        body: body,
        at: decoded['at'] is String
            ? DateTime.tryParse(decoded['at'] as String)
            : null,
        channel: decoded['channel'] as String?,
        from: decoded['from'] as String?,
        to: decoded['to'] as String?,
        subject: decoded['subject'] as String?,
        thread: decoded['thread'] as String?,
        externalId: decoded['external_id'] as String?,
      ));
    }
    return drafts;
  }

  /// Markdown。見出しでメッセージを区切る:
  ///
  /// ```md
  /// ## [inbound] 2026-08-11 10:24 山田様
  /// 本文...
  ///
  /// ## [outbound] 2026-08-11 12:00
  /// 本文...
  /// ```
  ///
  /// 見出し行の書式: `## [direction] [日時] [送信者名]`
  /// (日時・送信者名は省略可。本文は次の見出しまで)
  static final _headingPattern = RegExp(
    r'^#{1,6}\s*\[(inbound|outbound|in|out)\]\s*'
    r'(\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?)?)?\s*(.*)$',
  );

  static List<MessageDraft> parseMarkdown(String content) {
    final drafts = <MessageDraft>[];
    MessageDirection? currentDirection;
    DateTime? currentAt;
    String? currentName;
    final buffer = StringBuffer();

    void flush() {
      final direction = currentDirection;
      if (direction == null) return;
      final body = buffer.toString().trim();
      if (body.isEmpty) return;
      drafts.add(MessageDraft(
        direction: direction,
        body: body,
        at: currentAt,
        from: direction == MessageDirection.inbound ? currentName : null,
        to: direction == MessageDirection.outbound ? currentName : null,
      ));
    }

    for (final line in const LineSplitter().convert(content)) {
      final match = _headingPattern.firstMatch(line);
      if (match != null) {
        flush();
        buffer.clear();
        currentDirection = MessageRecord.directionFromString(match.group(1)!);
        final rawAt = match.group(2);
        currentAt =
            rawAt == null ? null : DateTime.tryParse(rawAt.replaceFirst(' ', 'T'));
        final name = match.group(3)?.trim();
        currentName = (name == null || name.isEmpty) ? null : name;
        continue;
      }
      if (currentDirection != null) buffer.writeln(line);
    }
    flush();
    return drafts;
  }
}

/// 取り込み元から読み取った、ID 採番前のメッセージ。
final class MessageDraft {
  final MessageDirection direction;
  final String body;
  final DateTime? at;
  final String? channel;
  final String? from;
  final String? to;
  final String? subject;
  final String? thread;
  final String? externalId;

  const MessageDraft({
    required this.direction,
    required this.body,
    this.at,
    this.channel,
    this.from,
    this.to,
    this.subject,
    this.thread,
    this.externalId,
  });
}
