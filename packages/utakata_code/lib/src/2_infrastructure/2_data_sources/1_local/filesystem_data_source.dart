import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../../1_domain/1_entities/structure/structure_node.dart';

/// ファイルシステム操作を担うデータソース
///
/// dart:io を直接使用する。Domain 層はこのクラスに依存しない。
class FilesystemDataSource {
  const FilesystemDataSource();

  /// ファイルを読み込む。存在しない場合は null を返す
  Future<String?> readFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  /// ファイルに書き込む（ディレクトリが存在しない場合は作成する）
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// ディレクトリを作成する（存在する場合は何もしない）
  Future<void> ensureDir(String path) async {
    await Directory(path).create(recursive: true);
  }

  /// ファイルを削除する(存在しなければ何もしない)
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  /// ディレクトリを再帰的に削除する(存在しなければ何もしない)
  Future<void> deleteDir(String path) async {
    final dir = Directory(path);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// ファイル/ディレクトリを移動する(移動先の親ディレクトリは自動作成)
  Future<void> movePath(String from, String to) async {
    final toParent = Directory(p.dirname(to));
    await toParent.create(recursive: true);
    if (Directory(from).existsSync()) {
      await Directory(from).rename(to);
    } else if (File(from).existsSync()) {
      await File(from).rename(to);
    }
  }

  /// ディレクトリ直下のエントリ名(ファイル・ディレクトリ)一覧を返す
  List<String> listEntries(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    return dir.listSync().map((e) => p.basename(e.path)).toList()..sort();
  }

  /// ファイルが存在するか確認する
  bool fileExists(String path) => File(path).existsSync();

  /// ディレクトリが存在するか確認する
  bool dirExists(String path) => Directory(path).existsSync();

  /// ディレクトリ配下のファイル・ディレクトリを再帰的にスキャンする
  ///
  /// .dart ファイル（.g.dart / .freezed.dart を除く）のみを対象とする
  Map<String, dynamic> scanDartFiles(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return {};
    return _scanDir(dir);
  }

  Map<String, dynamic> _scanDir(Directory dir) {
    final result = <String, dynamic>{};
    final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') || name == '.gitkeep') continue;

      if (entity is Directory) {
        result[name] = _scanDir(entity);
      } else if (entity is File) {
        final isDartFile = name.endsWith('.dart');
        final isGenerated =
            name.endsWith('.g.dart') || name.endsWith('.freezed.dart');
        if (isDartFile && !isGenerated) {
          final files = result['__files__'] as List<String>? ?? [];
          files.add(name);
          result['__files__'] = files;
        }
      }
    }
    return result;
  }

  /// ディレクトリ配下を再帰的にスキャンし、正準構造モデル
  /// ([StructureDirNode] / [StructureFileNode])のツリーを返す。
  ///
  /// `scanDartFiles`(Map ベースの旧表現)の後継。ファイル種別
  /// (source / generated)の判定は [StructureFileNode.kindOf] に一元化する。
  StructureDirNode scanStructureTree(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return StructureDirNode.empty;
    return _scanStructureDir(dir);
  }

  StructureDirNode _scanStructureDir(Directory dir) {
    final children = <String, StructureNode>{};
    final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') || name == '.gitkeep') continue;

      if (entity is Directory) {
        children[name] = _scanStructureDir(entity);
      } else if (entity is File && name.endsWith('.dart')) {
        children[name] = StructureFileNode(StructureFileNode.kindOf(name));
      }
    }
    return StructureDirNode(children);
  }

  /// ディレクトリ配下の .dart ファイルを再帰的にフラットリストで返す
  ///
  /// .g.dart / .freezed.dart / .template.dart は除外する。
  /// (命名規則の検証など、ツリー構造ではなくファイル単位の走査が必要な用途向け)
  List<String> listDartFilesRecursive(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !path.endsWith('.freezed.dart'))
        .where((path) => !path.endsWith('.g.dart'))
        .where((path) => !path.endsWith('.template.dart'))
        .toList()
      ..sort();
  }

  /// パッケージに同梱されたテンプレートディレクトリのパスを返す
  ///
  /// `dart:isolate` の `Isolate.resolvePackageUri` を使用して、
  /// グローバルインストール時やローカル実行時に関わらず確実にパスを解決する。
  Future<String> resolvePackageTemplatePath(String relativePath) async {
    final uri = await Isolate.resolvePackageUri(
        Uri.parse('package:utakata/src/0_templates/$relativePath'));
    if (uri != null) {
      return uri.toFilePath();
    }
    throw Exception('Failed to resolve package template path: $relativePath');
  }
}
