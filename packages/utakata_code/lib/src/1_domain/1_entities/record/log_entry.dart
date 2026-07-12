/// お客様会話ログの1メッセージ(仕様書 §7.1)。
///
/// 記録は人間が `utakata log add` で行う。AI は読み取り専用。
/// 形式非依存(JSONL への変換は infra 層の `log_entry_model.dart` が担う)。
enum Speaker { client, developer, system, thirdParty }

enum LogEntryKind { message, draft, note }

final class LogEntry {
  final String id; // MsgId.value
  final DateTime at;
  final bool atApprox;
  final Speaker speaker;
  final String? name;
  final LogEntryKind kind;
  final String body;
  final String? channel;
  final String? replyTo;
  final String? thread;
  final List<String> tags;
  final List<String> attachments;
  final DateTime? readAt;
  final String? sentAs;
  final DateTime recordedAt;
  final String recordedBy;

  const LogEntry({
    required this.id,
    required this.at,
    this.atApprox = false,
    required this.speaker,
    this.name,
    this.kind = LogEntryKind.message,
    required this.body,
    this.channel,
    this.replyTo,
    this.thread,
    this.tags = const [],
    this.attachments = const [],
    this.readAt,
    this.sentAs,
    required this.recordedAt,
    required this.recordedBy,
  });

  static Speaker speakerFromString(String raw) {
    switch (raw) {
      case 'client':
        return Speaker.client;
      case 'developer':
      case 'dev':
        return Speaker.developer;
      case 'system':
        return Speaker.system;
      case 'third_party':
      case 'third':
        return Speaker.thirdParty;
      default:
        throw ArgumentError('Unknown speaker: $raw');
    }
  }

  static String speakerToString(Speaker speaker) {
    switch (speaker) {
      case Speaker.client:
        return 'client';
      case Speaker.developer:
        return 'developer';
      case Speaker.system:
        return 'system';
      case Speaker.thirdParty:
        return 'third_party';
    }
  }

  static LogEntryKind kindFromString(String raw) {
    switch (raw) {
      case 'draft':
        return LogEntryKind.draft;
      case 'note':
        return LogEntryKind.note;
      default:
        return LogEntryKind.message;
    }
  }

  static String kindToString(LogEntryKind kind) {
    switch (kind) {
      case LogEntryKind.message:
        return 'message';
      case LogEntryKind.draft:
        return 'draft';
      case LogEntryKind.note:
        return 'note';
    }
  }
}
