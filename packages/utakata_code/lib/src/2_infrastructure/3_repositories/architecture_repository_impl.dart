import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/architecture_definition_entity.dart';
import '../../1_domain/1_entities/core_module_entity.dart';
import '../../1_domain/1_entities/guide_entity.dart';
import '../../1_domain/2_repositories/architecture_repository.dart';
import '../../1_domain/exceptions/domain_exceptions.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// アーキテクチャ定義リポジトリの実装
///
/// lib/src/0_templates/architectures/{id}/AI/architecture/arch_definition.yaml を読み込む。
class ArchitectureRepositoryImpl implements ArchitectureRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  const ArchitectureRepositoryImpl(this._fs, this._yaml);

  @override
  Future<ArchitectureDefinitionEntity> getById(String architectureId) async {
    final localPath = p.join(
      Directory.current.path,
      'AI',
      'architecture',
      'arch_definition.yaml',
    );

    if (_fs.fileExists(localPath)) {
      final localContent = await _fs.readFile(localPath);
      if (localContent != null) {
        final doc = _yaml.parse(localContent);
        if (doc != null) {
          final definition = _parseDefinition(doc);
          if (definition.id == architectureId) {
            return definition;
          }
        }
      }
    }

    final templateBase = await _fs.resolvePackageTemplatePath(
      p.join('architectures', architectureId, 'AI', 'architecture', 'arch_definition.yaml'),
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

    // guides セクションをパース
    final guides = <GuideEntity>[];
    final guidesList = doc['guides'];
    if (guidesList is List) {
      for (final guideMap in guidesList) {
        if (guideMap is Map) {
          final title = guideMap['title'] as String? ?? '';
          final layerPath = guideMap['layer_path'] as String? ?? '';
          final applyTo = guideMap['apply_to'] as String? ?? '';
          final doList = (guideMap['do_list'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final dontList = (guideMap['dont_list'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final allowedImports = (guideMap['allowed_imports'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final forbiddenImports = (guideMap['forbidden_imports'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final namingPattern = guideMap['naming_pattern'] as String? ?? '';
          final detailContentPath =
              guideMap['detail_content_path'] as String? ?? '';

          guides.add(GuideEntity(
            title: title,
            layerPath: layerPath,
            applyTo: applyTo,
            doList: doList,
            dontList: dontList,
            allowedImports: allowedImports,
            forbiddenImports: forbiddenImports,
            namingPattern: namingPattern,
            detailContentPath: detailContentPath,
          ));
        }
      }
    }

    // dependencies / dev_dependencies セクションをパース
    final dependencies = <String, dynamic>{};
    final depsMap = doc['dependencies'];
    if (depsMap is Map) {
      for (final entry in depsMap.entries) {
        dependencies[entry.key.toString()] = entry.value;
      }
    }

    final devDependencies = <String, dynamic>{};
    final devDepsMap = doc['dev_dependencies'];
    if (devDepsMap is Map) {
      for (final entry in devDepsMap.entries) {
        devDependencies[entry.key.toString()] = entry.value;
      }
    }

    // core_modules セクションをパース
    final coreModules = <CoreModuleEntity>[];
    final coreModulesList = doc['core_modules'];
    if (coreModulesList is List) {
      for (final coreModuleMap in coreModulesList) {
        if (coreModuleMap is Map) {
          final id = coreModuleMap['id'] as String? ?? '';
          final path = coreModuleMap['path'] as String? ?? '';
          final displayName = coreModuleMap['displayName'] as String? ?? '';
          if (id.isNotEmpty && path.isNotEmpty) {
            coreModules.add(CoreModuleEntity(
              id: id,
              path: path,
              displayName: displayName,
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
      guides: guides,
      dependencies: dependencies,
      devDependencies: devDependencies,
      coreModules: coreModules,
    );
  }

  @override
  Future<String> getRawDefinition(String architectureId) async {
    final localPath = p.join(
      Directory.current.path,
      'AI',
      'architecture',
      'arch_definition.yaml',
    );

    if (_fs.fileExists(localPath)) {
      final localContent = await _fs.readFile(localPath);
      if (localContent != null) {
        final doc = _yaml.parse(localContent);
        if (doc != null) {
          final definition = _parseDefinition(doc);
          if (definition.id == architectureId) {
            return localContent;
          }
        }
      }
    }

    final templateBase = await _fs.resolvePackageTemplatePath(
      p.join('architectures', architectureId, 'AI', 'architecture', 'arch_definition.yaml'),
    );

    final content = await _fs.readFile(templateBase);
    if (content == null) {
      throw ArchitectureNotFoundException(architectureId);
    }

    return content;
  }
}


