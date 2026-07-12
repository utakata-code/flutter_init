import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/record/log_entry.dart';
import '../../1_domain/2_repositories/conversation_log_repository.dart';
import '../1_models/log_entry_model.dart';
import '../2_data_sources/1_local/jsonl_data_source.dart';

/// `doc/records/log/YYYY-MM.jsonl` を月別ファイルとして扱う実装。
class ConversationLogRepositoryImpl implements ConversationLogRepository {
  final JsonlDataSource _jsonl;

  const ConversationLogRepositoryImpl(this._jsonl);

  static const _logDir = 'doc/records/log';

  String _monthPath(String projectDir, DateTime at) {
    final ym = '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';
    return p.join(projectDir, _logDir, '$ym.jsonl');
  }

  @override
  Future<void> append(String projectDir, LogEntry entry) async {
    await _jsonl.append(_monthPath(projectDir, entry.at), LogEntryModel.toMap(entry));
  }

  @override
  Future<String> nextId(String projectDir, DateTime at) async {
    final path = _monthPath(projectDir, at);
    final records = await _jsonl.readAll(path);
    final dateKey = '${at.year.toString().padLeft(4, '0')}'
        '${at.month.toString().padLeft(2, '0')}'
        '${at.day.toString().padLeft(2, '0')}';
    final prefix = 'MSG-$dateKey-';
    final sameDay = records
        .map((r) => r['id'] as String?)
        .whereType<String>()
        .where((id) => id.startsWith(prefix))
        .toList();
    final nextSeq = sameDay.length + 1;
    return '$prefix${nextSeq.toString().padLeft(3, '0')}';
  }

  @override
  Future<List<LogEntry>> query(
    String projectDir, {
    DateTime? date,
    String? thread,
    String? tag,
    String? id,
  }) async {
    final all = await readAll(projectDir);
    return all.where((entry) {
      if (date != null &&
          !(entry.at.year == date.year &&
              entry.at.month == date.month &&
              entry.at.day == date.day)) {
        return false;
      }
      if (thread != null && entry.thread != thread) return false;
      if (tag != null && !entry.tags.contains(tag)) return false;
      if (id != null && entry.id != id) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<LogEntry>> readAll(String projectDir) async {
    final dir = Directory(p.join(projectDir, _logDir));
    if (!dir.existsSync()) return [];

    final monthFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jsonl'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final entries = <LogEntry>[];
    for (final file in monthFiles) {
      final records = await _jsonl.readAll(file.path);
      entries.addAll(records.map(LogEntryModel.fromMap));
    }
    entries.sort((a, b) => a.at.compareTo(b.at));
    return entries;
  }

  @override
  Future<bool> exists(String projectDir, String id) async {
    final all = await readAll(projectDir);
    return all.any((e) => e.id == id);
  }
}
