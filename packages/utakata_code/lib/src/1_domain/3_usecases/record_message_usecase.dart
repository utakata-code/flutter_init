import '../1_entities/record/message_record.dart';
import '../2_repositories/message_repository.dart';
import '../services/date_resolver.dart';

/// `utakata message add` — 送受信原文を1件追記するユースケース(v1.6.0)。
///
/// 本文は**無加工**で保存する(一次証跡のため。要約は `log add` の役割)。
class RecordMessageUsecase {
  final MessageRepository _repo;

  const RecordMessageUsecase({required MessageRepository repo}) : _repo = repo;

  Future<RecordMessageResult> execute(
    String projectDir, {
    required String body,
    required String directionRaw,
    String? atRaw,
    required DateTime now,
    required String recordedBy,
    String? channel,
    String? from,
    String? to,
    String? subject,
    String? thread,
    String? externalId,
    List<String> attachments = const [],
  }) async {
    final direction = MessageRecord.directionFromString(directionRaw);
    final at = atRaw != null ? DateResolver.resolve(atRaw, now) : now;
    if (at.isAfter(now)) {
      throw ArgumentError('at ($at) must not be in the future');
    }
    if (body.trim().isEmpty) {
      throw ArgumentError('body must not be empty');
    }

    // `--external-id` は重複排除キー(doc/records.md)。add でも効かせる —
    // 効かないと、取り込みツールが再実行のたびに同じ原文を積んでしまう。
    if (externalId != null && externalId.isNotEmpty) {
      final existing = await _repo.readAll(projectDir);
      for (final record in existing) {
        if (record.externalId == externalId) {
          return RecordMessageResult(record: record, skipped: true);
        }
      }
    }

    final id = await _repo.nextId(projectDir, at);
    final record = MessageRecord(
      id: id,
      direction: direction,
      at: at,
      atApprox: atRaw == null,
      channel: channel,
      from: from,
      to: to,
      subject: subject,
      body: body,
      attachments: attachments,
      thread: thread,
      externalId: externalId,
      recordedAt: now,
      recordedBy: recordedBy,
    );

    await _repo.append(projectDir, record);
    return RecordMessageResult(record: record, skipped: false);
  }
}

/// `message add` の結果。
final class RecordMessageResult {
  final MessageRecord record;

  /// 同じ `external_id` が既にあり、追記しなかったか。
  final bool skipped;

  const RecordMessageResult({required this.record, required this.skipped});
}
