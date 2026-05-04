import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/architecture_definition_entity.dart';
import '../../1_domain/2_repositories/architecture_repository.dart';
import '../../1_domain/exceptions/domain_exceptions.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// アーキテクチャ定義リポジトリの実装
///
/// lib/src/0_templates/architectures/{id}/AI/arch_definition.yaml を読み込む。
class ArchitectureRepositoryImpl implements ArchitectureRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  const ArchitectureRepositoryImpl(this._fs, this._yaml);

  // TODO: ローカル優先読み込み — プロジェクトの AI/arch_definition.yaml が
  //       存在すればそちらを優先して使用する機能を実装する
  @override
  Future<ArchitectureDefinitionEntity> getById(String architectureId) async {
    final templateBase = await _fs.resolvePackageTemplatePath(
      p.join('architectures', architectureId, 'AI', 'arch_definition.yaml'),
    );

    final content = await _fs.readFile(templateBase);
    if (content == null) {
      throw ArchitectureNotFoundException(architectureId);
    }

    final doc = _yaml.parse(content);
    if (doc == null) {
      throw ArchitectureNotFoundException('$architectureId (YAML parse failed)');
    }

    return _parseDefinition(doc);
  }

  @override
  Future<List<ArchitectureDefinitionEntity>> getAll() async {
    final archsDir = await _fs.resolvePackageTemplatePath('architectures');
    final dir = Directory(archsDir);
    if (!dir.existsSync()) return [];

    final result = <ArchitectureDefinitionEntity>[];
    final entries = dir.listSync().whereType<Directory>().toList();
    for (final entry in entries) {
      try {
        result.add(await getById(p.basename(entry.path)));
      } catch (_) {
        // 読み込めないものはスキップ
      }
    }
    return result;
  }

  ArchitectureDefinitionEntity _parseDefinition(Map<String, dynamic> doc) {
    final layers = <LayerDefinitionEntity>[];
    final layersList = doc['layers'];
    if (layersList is List) {
      for (final layerMap in layersList) {
        if (layerMap is Map) {
          final name = layerMap['name'] as String? ?? '';
          final dirs = (layerMap['dirs'] as List?)
                  ?.map((d) => d.toString())
                  .toList() ??
              [];
          layers.add(LayerDefinitionEntity(name: name, dirs: dirs));
        }
      }
    }

    // naming_rules セクションをパース
    final namingRules = <NamingRuleEntity>[];
    final rulesList = doc['naming_rules'];
    if (rulesList is List) {
      for (final ruleMap in rulesList) {
        if (ruleMap is Map) {
          final dirPattern = ruleMap['dir_pattern'] as String? ?? '';
          final filePattern = ruleMap['file_pattern'] as String? ?? '';
          final description = ruleMap['description'] as String? ?? '';
          if (dirPattern.isNotEmpty && filePattern.isNotEmpty) {
            namingRules.add(NamingRuleEntity(
              dirPattern: dirPattern,
              filePattern: filePattern,
              description: description,
            ));
          }
        }
      }
    }

    return ArchitectureDefinitionEntity(
      id: doc['id'] as String? ?? '',
      displayName: doc['displayName'] as String? ?? '',
      layers: layers,
      namingRules: namingRules,
    );
  }
}

