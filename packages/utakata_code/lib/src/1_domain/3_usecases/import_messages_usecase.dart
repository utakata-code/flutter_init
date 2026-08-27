import 'dart:convert';
import 'dart:io' show stderr;

import '../1_entities/record/message_record.dart';
import '../services/date_resolver.dart';
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
  ///
  /// [sourceKey]: 取り込み元を識別する文字列(ファイルパス等)。取り込み元が
  /// `external_id` を持たない場合に、合成 ID の材料として使う。
  Future<List<ImportedMessage>> execute(
    String projectDir, {
    required String content,
    required String format,
    required DateTime now,
    required String recordedBy,
    String? defaultChannel,
    String? sourceKey,
    bool dryRun = false,
  }) async {
    final parsed = switch (format) {
      'jsonl' => parseJsonl(content),
      'md' => parseMarkdown(content),
      _ => throw ArgumentError('Unknown format: $format (jsonl|md)'),
    };

    // 取り込み元自体のハッシュ。同じソースを2回流したときだけ一致する。
    final sourceHash = _fnv1a('${sourceKey ?? ''} $content');

    // 既存レコードのキーは**1度だけ**読み出す(1件ごとに全月ファイルを
    // 読み直すと件数の二乗に比例して遅くなる)。
    final existing = await _repo.readAll(projectDir);
    final knownExternalIds = {
      for (final r in existing)
        if (r.externalId != null) r.externalId!,
    };
    final knownDedupeKeys = {for (final r in existing) r.dedupeKey};

    final results = <ImportedMessage>[];
    // 日付ごとの次連番をこの実行内で持ち回る。1件ごとに月ファイルを
    // 読み直さずに済み、追記しない dry-run でも実行時と同じ ID を出せる。
    final nextSeqPerDay = <String, int>{};

    for (var index = 0; index < parsed.length; index++) {
      final draft = parsed[index];
      // add と同じ検証を通す(取り込み経由なら壊れた値が入る、を作らない)
      if (draft.body.trim().isEmpty) {
        stderr.writeln('⚠️  ${index + 1} 件目: 本文が空のためスキップしました。');
        continue;
      }
      var at = draft.at ?? now;
      if (at.isAfter(now)) {
        stderr.writeln('⚠️  ${index + 1} 件目: 日時 $at が未来のため'
            '記録時刻に置き換えました。');
        at = now;
      }
      // 取り込み元に ID が無ければ「ソース + 位置」から合成する。これにより
      //   (a) 同じソースを再度流してもスキップされ、
      //   (b) 同一本文が複数回現れても別メッセージとして残る
      // (日時が原文に無い md では at が実行時刻になるため、本文ハッシュだけ
      //  では同じ文面が消えてしまう)。
      final externalId = draft.externalId ?? '$format:$sourceHash:$index';
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
        externalId: externalId,
        recordedAt: now,
        recordedBy: recordedBy,
      );

      // external_id が判定の主軸。本文ハッシュによる判定は「取り込み元に
      // ID が無く、日時が原文由来である」場合のみ併用する(別 ID の同文面を
      // 取りこぼさないため)。
      final duplicated = knownExternalIds.contains(externalId) ||
          (draft.externalId == null &&
              draft.at != null &&
              knownDedupeKeys.contains(provisional.dedupeKey));
      if (duplicated) {
        results.add(ImportedMessage(record: provisional, skipped: true));
        continue;
      }
      knownExternalIds.add(externalId);
      knownDedupeKeys.add(provisional.dedupeKey);

      final dayKey = at.toIso8601String().substring(0, 10);
      if (!nextSeqPerDay.containsKey(dayKey)) {
        nextSeqPerDay[dayKey] = _sequenceOf(await _repo.nextId(projectDir, at));
      }
      final seq = nextSeqPerDay[dayKey]!;
      nextSeqPerDay[dayKey] = seq + 1;
      final id = 'MSGR-${dayKey.replaceAll('-', '')}-'
          '${seq.toString().padLeft(3, '0')}';
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

  /// `2026-02-31` のような実在しない日付を弾く厳密パース。
  /// `DateTime.parse` は繰り上げてしまうため、往復で一致するか確認する。
  static DateTime? _strictParse(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final datePart = raw.length >= 10 ? raw.substring(0, 10) : raw;
    if (parsed.toIso8601String().substring(0, 10) != datePart) return null;
    // `add` と同じくローカルへ揃える(揃えないと同じ日時が経路によって
    // 別の日・別の月ファイルに落ちる)
    return DateResolver.toLocal(parsed);
  }

  /// `MSGR-YYYYMMDD-NNN` の連番部分を取り出す。
  static int _sequenceOf(String id) =>
      int.tryParse(id.substring(id.lastIndexOf('-') + 1)) ?? 1;

  /// 取り込み元の同一性判定に使う FNV-1a 64bit(依存を増やさないため自前)。
  static String _fnv1a(String input) {
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// JSONL(1行1メッセージ)。キーは `doc/records/messages/` と同じ。
  ///
  /// 壊れた行・必須項目を欠く行は、その行だけ飛ばして続行する
  /// (1行のせいで取り込み全体が中止されると、どこが悪いのか分からない)。
  /// 飛ばした行は行番号つきで stderr に出す。
  static List<MessageDraft> parseJsonl(String content) {
    final drafts = <MessageDraft>[];
    final lines = const LineSplitter().convert(content);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      Object? decoded;
      try {
        decoded = jsonDecode(line);
      } on FormatException {
        stderr.writeln('⚠️  ${i + 1} 行目: JSON として解釈できないためスキップしました。');
        continue;
      }
      if (decoded is! Map<String, dynamic>) {
        stderr.writeln('⚠️  ${i + 1} 行目: オブジェクトではないためスキップしました。');
        continue;
      }

      final direction = decoded['direction'];
      final body = decoded['body'];
      if (direction is! String || body is! String) {
        stderr.writeln('⚠️  ${i + 1} 行目: direction / body が文字列でないため'
            'スキップしました。');
        continue;
      }
      final MessageDirection parsedDirection;
      try {
        parsedDirection = MessageRecord.directionFromString(direction);
      } on ArgumentError {
        stderr.writeln('⚠️  ${i + 1} 行目: direction "$direction" は '
            'inbound / outbound ではないためスキップしました。');
        continue;
      }

      final rawAt = decoded['at'];
      DateTime? at;
      if (rawAt is String) {
        // オフセット付き / Z 付きはローカルへ正規化する。`message add` は
        // DateResolver 経由で正規化しており、揃えないと同じ時刻が
        // import と add で別の日付・別の月ファイルになる。
        final parsed = DateTime.tryParse(rawAt);
        at = parsed == null ? null : DateResolver.toLocal(parsed);
        if (at == null) {
          stderr.writeln('⚠️  ${i + 1} 行目: at "$rawAt" を日時として'
              '解釈できません(記録時刻を使います)。');
        }
      }

      drafts.add(MessageDraft(
        direction: parsedDirection,
        body: body,
        at: at,
        channel: decoded['channel']?.toString(),
        from: decoded['from']?.toString(),
        to: decoded['to']?.toString(),
        subject: decoded['subject']?.toString(),
        thread: decoded['thread']?.toString(),
        externalId: decoded['external_id']?.toString(),
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
    var inCodeFence = false;
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
      // コードブロック内の見出し風の行は本文の一部(区切りにしない)
      if (line.trimLeft().startsWith('```')) {
        inCodeFence = !inCodeFence;
        if (currentDirection != null) buffer.writeln(line);
        continue;
      }
      final match = inCodeFence ? null : _headingPattern.firstMatch(line);
      if (match != null) {
        flush();
        buffer.clear();
        currentDirection = MessageRecord.directionFromString(match.group(1)!);
        final rawAt = match.group(2);
        currentAt = rawAt == null
            ? null
            : _strictParse(rawAt.replaceFirst(' ', 'T'));
        if (rawAt != null && currentAt == null) {
          stderr.writeln('⚠️  見出しの日時 "$rawAt" は実在しない日付です'
              '(記録時刻を使います)。');
        }
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
