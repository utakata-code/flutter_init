import 'package:path/path.dart' as p;

import '../../1_domain/2_repositories/project_repository.dart';
import '../../1_domain/exceptions/domain_exceptions.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// プロジェクトリポジトリの実装
///
/// AI/specs/ と AI/snapshots/ 配下の YAML ファイルを操作する。
class ProjectRepositoryImpl implements ProjectRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  const ProjectRepositoryImpl(this._fs, this._yaml);

  static const _featureRequestPath = 'AI/specs/feature_request.yaml';
  static const _planArchYamlPath = 'AI/specs/plan_architecture.yaml';
  static const _currentStructYamlPath = 'AI/snapshots/current_structure.yaml';
  static const _projectStatusYamlPath = 'AI/snapshots/project_status.yaml';
  static const _featuresDir = 'lib/features';

  @override
  Future<Map<String, dynamic>> readFeatureRequest(String projectDir) async {
    final path = p.join(projectDir, _featureRequestPath);
    final content = await _fs.readFile(path);
    if (content == null) {
      throw FeatureRequestNotFoundException(path);
    }
    final doc = _yaml.parse(content);
    if (doc == null) {
      throw YamlParseException(path);
    }
    return doc;
  }

  @override
  Future<void> writePlanArchitecture(
    String projectDir,
    Map<String, dynamic> plan,
  ) async {
    final yamlStr = _yaml.serialize(plan);
    await _fs.writeFile(p.join(projectDir, _planArchYamlPath), yamlStr);
  }

  @override
  Future<Map<String, dynamic>?> readPlanArchitecture(String projectDir) async {
    final content = await _fs.readFile(p.join(projectDir, _planArchYamlPath));
    if (content == null) return null;
    return _yaml.parse(content);
  }

  @override
  Future<Map<String, dynamic>?> readCurrentStructure(String projectDir) async {
    final content =
        await _fs.readFile(p.join(projectDir, _currentStructYamlPath));
    if (content == null) return null;
    return _yaml.parse(content);
  }

  @override
  Future<void> writeCurrentStructure(
    String projectDir,
    Map<String, dynamic> structure,
  ) async {
    final yamlStr = _yaml.serialize({'features': structure});
    await _fs.writeFile(
      p.join(projectDir, _currentStructYamlPath),
      yamlStr,
    );
  }

  @override
  Future<Map<String, dynamic>> scanFeaturesStructure(String projectDir) async {
    final featDir = p.join(projectDir, _featuresDir);
    return _fs.scanDartFiles(featDir);
  }

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
}
