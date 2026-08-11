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

    // 件数ではなく**既存の最大連番 + 1**。行が削除されたり破損して読めない
    // 場合でも、既に使った ID を再発行しない(ID 重複は show/link の
    // 取り違えに直結する)。
    var maxSeq = 0;
    for (final row in records) {
      final id = row['id'];
      if (id is! String || !id.startsWith(prefix)) continue;
      final seq = int.tryParse(id.substring(prefix.length));
      if (seq != null && seq > maxSeq) maxSeq = seq;
    }
    return '$prefix${(maxSeq + 1).toString().padLeft(3, '0')}';
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
    var skipped = 0;
    for (final file in monthFiles) {
      final rows = await _jsonl.readAll(file.path);
      for (final row in rows) {
        // JSON としては正しいがスキーマが違う行(手編集・別ツール由来)は
        // 全体を落とさずスキップし、件数だけ警告する。
        final record = MessageRecordModel.tryFromMap(row);
        if (record == null) {
          skipped++;
          continue;
        }
        records.add(record);
      }
    }
    if (skipped > 0) {
      stderr.writeln('⚠️  doc/records/messages/ に解釈できない行が $skipped 件あります'
          '(スキップしました)。');
    }
    // 同時刻でも順序が決まるよう ID を第2キーにする(非安定ソート対策)。
    records.sort((a, b) {
      final byAt = a.at.compareTo(b.at);
      return byAt != 0 ? byAt : a.id.compareTo(b.id);
    });
    return records;
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
      // **生行**を読む(パース済みの Map ではなく)。対象行だけ差し替え、
      // 他の行はバイトのまま書き戻す — 破損行や未知フィールドを持つ行を
      // link のたびに失わないため。
      final lines = await file.readAsLines();
      var targetIndex = -1;
      Map<String, dynamic>? targetRow;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        try {
          final decoded = jsonDecode(lines[i]);
          if (decoded is Map<String, dynamic> && decoded['id'] == id) {
            targetIndex = i;
            targetRow = decoded;
            break;
          }
        } on FormatException {
          continue; // 破損行はそのまま保持する
        }
      }
      if (targetIndex < 0 || targetRow == null) continue;

      // 既存キーを保ったまま参照だけ差分マージする(モデルが知らない
      // フィールドも消さない。本文にも触れない)。
      final merged = <String, dynamic>{
        ...targetRow,
        if (logRef != null) 'log_ref': logRef,
        if (agreementRef != null) 'agreement_ref': agreementRef,
      };
      lines[targetIndex] = jsonEncode(merged);

      // 一時ファイル + rename で原子的に置換する(書き込み中断で
      // 月ファイルごと失わないため)。
      final temp = File('${file.path}.tmp');
      await temp.writeAsString('${lines.join('\n')}\n', flush: true);
      await temp.rename(file.path);
      return true;
    }
    return false;
  }
}
