import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/template_file_entity.dart';
import '../../1_domain/2_repositories/template_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';

/// テンプレートリポジトリの実装
///
/// lib/src/0_templates/architectures/{archId}/ 配下のテンプレートを読み込む。
/// すべてのリソースがアーキテクチャ単位でまとまっている:
///   architectures/{archId}/
///     .agent/         — 旧 AI エージェント設定(v1.0 で生成停止。Claude Code
///                        統合(.claude/ + .mcp.json)が後継。ディレクトリ自体は
///                        参考資料として残るが getProjectTemplates では読まない)
///     AI/             — AI ガイド・テンプレート・仕様書
///       architecture/  — アーキテクチャ固有リソース
///         arch_definition.yaml
///         features/    — フィーチャー用 .tmpl + GUIDE.md
///         guides/      — アーキテクチャガイド
///         core/        — Core 層ガイド
///       specs/         — 仕様書テンプレート
///       scripts/       — ユーティリティスクリプト
///       snapshots/     — スナップショット
///       logs/          — ログ
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
      p.join('architectures', architectureId, 'AI', 'architecture', 'features'),
    );
    return _loadTemplates(basePath, tmplOnly: true);
  }

  @override
  Future<List<TemplateFileEntity>> getProjectTemplates(String architectureId) async {
    final archBasePath = await _fs.resolvePackageTemplatePath(
      p.join('architectures', architectureId),
    );

    final results = <TemplateFileEntity>[];

    // AI/ ディレクトリ全体（プレフィックス付きで展開: AI/guides/... のように）
    // features/*.tmpl は .tmpl 拡張子をそのまま保持して展開される
    final aiDir = Directory(p.join(archBasePath, 'AI'));
    if (aiDir.existsSync()) {
      results.addAll(await _loadTemplates(
        aiDir.path,
        addBaseDirPrefix: true,
      ));
    }

    // .agent/ は v1.0 で生成を停止した(仕様書 §11.3)。
    // Claude Code 統合(.claude/ + .mcp.json)が後継。

    return results;
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
