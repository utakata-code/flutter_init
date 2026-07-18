import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/config/utakata_config_entity.dart';
import '../../1_domain/2_repositories/config_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// [ConfigRepository] の実装。`utakata.yaml` をプロジェクトルートから読む。
class ConfigRepositoryImpl implements ConfigRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  const ConfigRepositoryImpl(this._fs, this._yaml);

  static const _configFileName = 'utakata.yaml';

  @override
  Future<UtakataConfig?> read(String projectDir) async {
    final path = p.join(projectDir, _configFileName);
    final content = await _fs.readFile(path);
    if (content == null) return null;
    final doc = _yaml.parse(content, source: path);
    return UtakataConfig.fromMap(doc);
  }

  @override
  Future<List<String>> validate(String projectDir) async {
    final path = p.join(projectDir, _configFileName);
    final content = await _fs.readFile(path);
    if (content == null) return const [];

    final issues = <String>[];
    final Map<String, dynamic> doc;
    try {
      doc = _yaml.parse(content, source: path);
    } catch (e) {
      return ['utakata.yaml の YAML が壊れています: $e'];
    }

    final schema = doc['schema'];
    if (schema is int && schema > UtakataConfig.currentSchema) {
      issues.add('utakata.yaml の schema: $schema はこの CLI(schema: '
          '${UtakataConfig.currentSchema})より新しく、解釈できません。CLI を更新してください。');
    }

    for (final key in doc.keys) {
      if (!UtakataConfig.knownTopLevelKeys.contains(key)) {
        issues.add('utakata.yaml に未知のトップレベルキー "$key" があります(タイポの可能性)。');
      }
    }

    return issues;
  }
}
