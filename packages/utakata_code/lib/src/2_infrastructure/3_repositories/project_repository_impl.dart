import 'package:path/path.dart' as p;

import '../../1_domain/2_repositories/project_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// プロジェクトリポジトリの実装
///
/// `doc/preview/` 配下へ導出結果を書き出す(v1.6.0〜)。
/// v1.5.x までは `AI/snapshots/` に書いていたが、`doctor --migrate` が
/// 同ディレクトリを「導出可能な生成物」として削除する一方で status が
/// 書き戻すという食い違いがあったため、`doc/` に統一した。
class ProjectRepositoryImpl implements ProjectRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  const ProjectRepositoryImpl(this._fs, this._yaml);

  static const _projectStatusYamlPath = 'doc/preview/project_status.yaml';
  static const _projectStatusMdPath = 'doc/preview/project_status.md';

  @override
  Future<void> writeProjectStatus(
    String projectDir,
    Map<String, dynamic> status,
  ) async {
    final header = '# project_status.yaml\n'
        '# 自動生成 — 手動編集しないでください\n'
        '# 生成日時: ${DateTime.now().toIso8601String()}\n\n';
    final yamlStr = _yaml.serialize(status);
    await _fs.writeFile(
      p.join(projectDir, _projectStatusYamlPath),
      header + yamlStr,
    );
  }

  @override
  Future<void> writeProjectStatusMarkdown(
    String projectDir,
    String markdown,
  ) async {
    await _fs.writeFile(
      p.join(projectDir, _projectStatusMdPath),
      markdown,
    );
  }
}
