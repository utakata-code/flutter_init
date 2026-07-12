import '../1_entities/record/log_entry.dart';
import '../2_repositories/conversation_log_repository.dart';
import '../services/date_resolver.dart';

/// `utakata log add` — 会話ログを1件追記するユースケース。
///
/// 記録は人間のコマンド経由でのみ行う(仕様書 §7.1・P8)。
class AddLogEntryUsecase {
  final ConversationLogRepository _repo;

  const AddLogEntryUsecase({required ConversationLogRepository repo}) : _repo = repo;

  Future<LogEntry> execute(
    String projectDir, {
    required String body,
    required String speakerRaw,
    String? atRaw,
    required DateTime now,
    required String recordedBy,
    String? name,
    String? thread,
    List<String> tags = const [],
    String? replyTo,
    bool isDraft = false,
    String? sentAs,
  }) async {
    final at = atRaw != null ? DateResolver.resolve(atRaw, now) : now;
    if (at.isAfter(now)) {
      throw ArgumentError('at ($at) must not be in the future');
    }

    if (replyTo != null && !await _repo.exists(projectDir, replyTo)) {
      throw ArgumentError('reply_to "$replyTo" does not exist');
    }

    final id = await _repo.nextId(projectDir, at);

    final entry = LogEntry(
      id: id,
      at: at,
      speaker: LogEntry.speakerFromString(speakerRaw),
      name: name,
      kind: isDraft ? LogEntryKind.draft : LogEntryKind.message,
      body: body,
      thread: thread,
      tags: tags,
      replyTo: replyTo,
      sentAs: sentAs,
      recordedAt: now,
      recordedBy: recordedBy,
    );

    await _repo.append(projectDir, entry);
    return entry;
  }
}
