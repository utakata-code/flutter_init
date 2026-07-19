import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/template_file_entity.dart';
import '../../1_domain/2_repositories/template_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';

/// テンプレートリポジトリの実装
///
/// lib/src/0_templates/architectures/{archId}/ 配下(utakata_arch_lib から
/// tool/sync_arch_lib.dart が同期した同梱コピー)を読み込む:
///   architectures/{archId}/
///     arch_definition.yaml — 機械可読定義(構造・命名規則・ガイド)
///     principles/          — 絶対遵守ルール
///     layers/              — レイヤーごとの GUIDE.md
///     dependencies/        — 推奨パッケージ
///     skills/              — Claude Code SKILL(skills sync が同期)
///
/// v1.0.0(S2)から、ナレッジはプロジェクトへコピーせず参照する
/// (getProjectTemplates は空を返す。guide show/eject・MCP guide_get が後継)。
class TemplateRepositoryImpl implements TemplateRepository {
  final FilesystemDataSource _fs;

  const TemplateRepositoryImpl(this._fs);

  @override
  Future<List<TemplateFileEntity>> getFeatureTemplates(String architectureId) async {
    final localPath = p.join(
      Directory.current.path,
      'AI',
      'architecture',
      'features',
    );

    if (_fs.dirExists(localPath)) {
      return _loadTemplates(localPath, tmplOnly: true);
    }

    final basePath = await _fs.resolvePackageTemplatePath(
      p.join('architectures', architectureId, 'layers', 'features'),
    );
    return _loadTemplates(basePath, tmplOnly: true);
  }

  @override
  Future<List<TemplateFileEntity>> getProjectTemplates(String architectureId) async {
    // v1.0.0(S2)からナレッジの丸ごとコピーを廃止(コンテキスト分離)。
    // ガイドは guide show/eject・MCP guide_get で参照し、プロジェクトには
    // doc/(doc init)と .claude/(create)だけが生成される。
    return const [];
  }

  /// ディレクトリ配下のファイルを再帰的に読み込む
  ///
  /// [tmplOnly] が true の場合は .tmpl ファイルのみ対象とし、
  /// 拡張子を除去して展開する。false の場合はすべてのファイルを対象とする。
  /// [addBaseDirPrefix] が true の場合、ベースディレクトリ名をパスに付与する
  /// （utakata/guides/... や .agent/rules/... のように展開するため）
  Future<List<TemplateFileEntity>> _loadTemplates(
    String dirPath, {
    String? excludePattern,
    bool tmplOnly = false,
    bool addBaseDirPrefix = false,
  }) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    final results = <TemplateFileEntity>[];
    final entities = dir.listSync(recursive: true);

    for (final entity in entities) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);

      // .gitkeep は無視
      if (name == '.gitkeep') continue;
      if (excludePattern != null && name == excludePattern) continue;

      // tmplOnly モードでは .tmpl ファイルのみ対象
      if (tmplOnly && !name.endsWith('.tmpl')) continue;

      // テンプレートのパスをベースディレクトリからの相対パスにする
      String relativePath = p.relative(entity.path, from: dirPath);

      // .tmpl 拡張子は tmplOnly モード（コード生成時）のみ除去する
      // プロジェクトテンプレートとしてコピーする場合は .tmpl をそのまま保持
      if (tmplOnly && relativePath.endsWith('.tmpl')) {
        relativePath = relativePath.substring(
          0,
          relativePath.length - '.tmpl'.length,
        );
      }

      // 必要に応じてベースディレクトリ名をプレフィックスとして付与
      if (addBaseDirPrefix) {
        final baseDirName = p.basename(dirPath);
        relativePath = p.join(baseDirName, relativePath);
      }

      final content = await entity.readAsString();
      results.add(TemplateFileEntity(
        relativePath: relativePath,
        content: content,
      ));
    }

    return results;
  }
}
