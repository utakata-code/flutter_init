import 'dart:convert';
import 'dart:io';

/// JSONL(1行=1レコード)の追記専用データソース。
///
/// 追記は末尾への1行書き込みのみ(O(1))。破損行(前回クラッシュ等)は
/// 読み込み時に検出し、`.corrupt` へ退避してスキップする(握りつぶさない)。
class JsonlDataSource {
  const JsonlDataSource();

  /// 1レコードを末尾に追記する(ファイルが無ければ作成)。
  Future<void> append(String path, Map<String, dynamic> record) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.append);
    sink.writeln(jsonEncode(record));
    await sink.flush();
    await sink.close();
  }

  /// 全レコードを読み出す。ファイルが無ければ空リスト。
  ///
  /// 破損した行(JSON として parse できない行)は `<path>.corrupt` へ
  /// 追記退避し、結果には含めない。
  Future<List<Map<String, dynamic>>> readAll(String path) async {
    final file = File(path);
    if (!file.existsSync()) return [];

    final lines = await file.readAsLines();
    final records = <Map<String, dynamic>>[];
    final corruptLines = <String>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(line);
        if (decoded is Map<String, dynamic>) {
          records.add(decoded);
        } else {
          corruptLines.add(line);
        }
      } on FormatException {
        corruptLines.add(line);
      }
    }

    if (corruptLines.isNotEmpty) {
      // readAll は繰り返し呼ばれるため、既に退避済みの行は書かない
      // (同じ破損行が読むたびに積み上がって肥大するのを防ぐ)。
      final corruptFile = File('$path.corrupt');
      final alreadySaved = corruptFile.existsSync()
          ? (await corruptFile.readAsLines()).toSet()
          : <String>{};
      final newLines =
          corruptLines.where((line) => !alreadySaved.contains(line)).toList();
      if (newLines.isNotEmpty) {
        final sink = corruptFile.openWrite(mode: FileMode.append);
        for (final line in newLines) {
          sink.writeln(line);
        }
        await sink.flush();
        await sink.close();
      }
    }

    return records;
  }

  bool exists(String path) => File(path).existsSync();
}
