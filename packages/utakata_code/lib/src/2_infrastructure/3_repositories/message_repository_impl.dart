import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/record/message_record.dart';
import '../../1_domain/2_repositories/message_repository.dart';
import '../1_models/message_record_model.dart';
import '../2_data_sources/1_local/jsonl_data_source.dart';

/// `doc/records/messages/YYYY-MM.jsonl` を月別ファイルとして扱う実装。
class MessageRepositoryImpl implements MessageRepository {
  final JsonlDataSource _jsonl;

  const MessageRepositoryImpl(this._jsonl);

  static const _messagesDir = 'doc/records/messages';

  static String _monthKey(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';

  String _monthPath(String projectDir, DateTime at) =>
      p.join(projectDir, _messagesDir, '${_monthKey(at)}.jsonl');

  @override
  Future<void> append(String projectDir, MessageRecord record) async {
    await _jsonl.append(
      _monthPath(projectDir, record.at),
      MessageRecordModel.toMap(record),
    );
  }

  @override
  Future<String> nextId(String projectDir, DateTime at) async {
    final records = await _jsonl.readAll(_monthPath(projectDir, at));
    final dateKey = '${at.year.toString().padLeft(4, '0')}'
        '${at.month.toString().padLeft(2, '0')}'
        '${at.day.toString().padLeft(2, '0')}';
    final prefix = 'MSGR-$dateKey-';
    final sameDay = records
        .map((r) => r['id'] as String?)
        .whereType<String>()
        .where((id) => id.startsWith(prefix))
        .length;
    return '$prefix${(sameDay + 1).toString().padLeft(3, '0')}';
  }

  @override
  Future<List<MessageRecord>> query(
    String projectDir, {
    MessageDirection? direction,
    String? channel,
    String? thread,
    String? month,
    String? id,
  }) async {
    final all = await readAll(projectDir);
    return all.where((record) {
      if (direction != null && record.direction != direction) return false;
      if (channel != null && record.channel != channel) return false;
      if (thread != null && record.thread != thread) return false;
      if (month != null && _monthKey(record.at) != month) return false;
      if (id != null && record.id != id) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<MessageRecord>> readAll(String projectDir) async {
    final dir = Directory(p.join(projectDir, _messagesDir));
    if (!dir.existsSync()) return [];

    final monthFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jsonl'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final records = <MessageRecord>[];
    for (final file in monthFiles) {
      final rows = await _jsonl.readAll(file.path);
      records.addAll(rows.map(MessageRecordModel.fromMap));
    }
    records.sort((a, b) => a.at.compareTo(b.at));
    return records;
  }

  @override
  Future<bool> existsDuplicate(
    String projectDir, {
    String? externalId,
    String? dedupeKey,
  }) async {
    if (externalId == null && dedupeKey == null) return false;
    final all = await readAll(projectDir);
    return all.any((record) {
      if (externalId != null && record.externalId == externalId) return true;
      if (dedupeKey != null && record.dedupeKey == dedupeKey) return true;
      return false;
    });
  }

  @override
  Future<bool> link(
    String projectDir,
    String id, {
    String? logRef,
    String? agreementRef,
  }) async {
    final dir = Directory(p.join(projectDir, _messagesDir));
    if (!dir.existsSync()) return false;

    for (final file in dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.jsonl'),
        )) {
      final rows = await _jsonl.readAll(file.path);
      final index = rows.indexWhere((r) => r['id'] == id);
      if (index < 0) continue;

      final updated = MessageRecordModel.fromMap(rows[index])
          .copyWith(logRef: logRef, agreementRef: agreementRef);
      rows[index] = MessageRecordModel.toMap(updated);
      // 参照の付与のみファイル全体を書き直す(本文には触れない)。
      await file.writeAsString(
        '${rows.map(jsonEncode).join('\n')}\n',
      );
      return true;
    }
    return false;
  }
}
