import '../1_entities/record/message_record.dart';
import '../2_repositories/message_repository.dart';
import '../services/date_resolver.dart';

/// `utakata message add` — 送受信原文を1件追記するユースケース(v1.6.0)。
///
/// 本文は**無加工**で保存する(一次証跡のため。要約は `log add` の役割)。
class RecordMessageUsecase {
  final MessageRepository _repo;

  const RecordMessageUsecase({required MessageRepository repo}) : _repo = repo;

  Future<MessageRecord> execute(
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
    return record;
  }
}
