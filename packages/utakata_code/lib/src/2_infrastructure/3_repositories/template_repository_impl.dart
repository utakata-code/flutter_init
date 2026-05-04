import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/template_file_entity.dart';
import '../../1_domain/2_repositories/template_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';

/// テンプレートリポジトリの実装
///
/// lib/src/templates/ 配下の .dart.tmpl ファイルを読み込む。
class TemplateRepositoryImpl implements TemplateRepository {
  final FilesystemDataSource _fs;

  const TemplateRepositoryImpl(this._fs);

  @override
  Future<List<TemplateFileEntity>> getFeatureTemplates(String architectureId) async {
    final basePath = _fs.resolvePackageTemplatePath(
      p.join('features', architectureId),
    );
    return _loadTemplates(basePath);
  }

  @override
  Future<List<TemplateFileEntity>> getProjectTemplates(String architectureId) async {
    final basePath = _fs.resolvePackageTemplatePath(
      p.join('architectures', architectureId),
    );
    // arch_definition.yaml を除くすべてのファイルをテンプレートとして扱う
    return _loadTemplates(basePath, excludePattern: 'arch_definition.yaml');
  }

  /// ディレクトリ配下の .dart.tmpl ファイルを再帰的に読み込む
  Future<List<TemplateFileEntity>> _loadTemplates(
    String dirPath, {
    String? excludePattern,
  }) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    final results = <TemplateFileEntity>[];
    final entities = dir.listSync(recursive: true);

    for (final entity in entities) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (excludePattern != null && name == excludePattern) continue;
      if (!name.endsWith('.tmpl')) continue;

      // テンプレートのパスをベースディレクトリからの相対パスにする
      // .tmpl 拡張子を除去して本来のファイル名にする
      final relativePath = p
          .relative(entity.path, from: dirPath)
          .replaceAll('.tmpl', '');

      final content = await entity.readAsString();
      results.add(TemplateFileEntity(
        relativePath: relativePath,
        content: content,
      ));
    }

    return results;
  }
}
