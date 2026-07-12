import '../1_entities/record/log_entry.dart';
import '../2_repositories/conversation_log_repository.dart';

/// `utakata log show` — 会話ログの検索(--date/--thread/--tag/ID)。
class QueryLogUsecase {
  final ConversationLogRepository _repo;

  const QueryLogUsecase({required ConversationLogRepository repo}) : _repo = repo;

  Future<List<LogEntry>> execute(
    String projectDir, {
    DateTime? date,
    String? thread,
    String? tag,
    String? id,
  }) =>
      _repo.query(projectDir, date: date, thread: thread, tag: tag, id: id);
}
