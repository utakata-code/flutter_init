import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/config/utakata_config_entity.dart';
import '../../1_domain/2_repositories/config_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// [ConfigRepository] の実装。`utakata.yaml` をプロジェクトルートから読む。
class ConfigRepositoryImpl implements ConfigRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  /// `~/.utakata/config.yaml` を解決するためのホームディレクトリ。
  final String? _homeDir;

  const ConfigRepositoryImpl(this._fs, this._yaml, {String? homeDir})
      : _homeDir = homeDir;

  static const _configFileName = 'utakata.yaml';
  static const _globalConfigRelativePath = '.utakata/config.yaml';

  @override
  Future<UtakataConfig?> read(String projectDir) async {
    final path = p.join(projectDir, _configFileName);
    final content = await _fs.readFile(path);
    if (content == null) return null;
    final doc = _yaml.parse(content, source: path);
    return UtakataConfig.fromMap(doc);
  }

  @override
  Future<UtakataConfig?> readGlobal() async {
    final home = _homeDir;
    if (home == null || home.isEmpty) return null;
    final path = p.join(home, _globalConfigRelativePath);
    final content = await _fs.readFile(path);
    if (content == null) return null;
    return UtakataConfig.fromMap(_yaml.parse(content, source: path));
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

    // enforcement も誤記が黙って無効化される(ゲートが効かない)ので検証する
    final enforcement = doc['enforcement'];
    if (enforcement is Map) {
      for (final key in enforcement.keys) {
        if (key.toString() != 'impl_plan') {
          issues.add('utakata.yaml の enforcement に未知のキー "$key" が'
              'あります(タイポの可能性)。');
        }
      }
      final implPlan = enforcement['impl_plan'];
      if (implPlan != null &&
          implPlan.toString() != 'on' &&
          implPlan.toString() != 'off') {
        issues.add('enforcement.impl_plan: "$implPlan" は未対応の値です'
            '(on | off)。既定の off として扱われます。');
      }
    }

    // records セクションは誤記が「黙って既定(none)に落ちる」ため、
    // 値・キーの妥当性を明示的に報告する(気づけないと権限設定が効かない)。
    final records = doc['records'];
    if (records is Map) {
      const knownRecordKeys = {'git', 'agent_write', 'agent_read'};
      for (final key in records.keys) {
        if (!knownRecordKeys.contains(key.toString())) {
          issues.add('utakata.yaml の records に未知のキー "$key" があります'
              '(タイポの可能性)。');
        }
      }

      final agentWrite = records['agent_write'];
      if (agentWrite != null &&
          !UtakataConfig.agentWriteModes.contains(agentWrite.toString())) {
        issues.add('records.agent_write: "$agentWrite" は未対応の値です'
            '(${UtakataConfig.agentWriteModes.join(" | ")})。'
            '既定の none として扱われます。');
      }

      final agentRead = records['agent_read'];
      if (agentRead is Map) {
        for (final entry in agentRead.entries) {
          if (entry.key.toString() != 'messages') {
            issues.add('records.agent_read の "${entry.key}" は未対応のキーです'
                '(現在は messages のみ)。');
          } else if (entry.value is! bool) {
            issues.add('records.agent_read.messages は true / false で'
                '指定してください(現在: ${entry.value})。');
          }
        }
      } else if (agentRead != null) {
        issues.add('records.agent_read はマップで指定してください'
            '(例: agent_read:\\n    messages: true)。');
      }
    }

    return issues;
  }
}
