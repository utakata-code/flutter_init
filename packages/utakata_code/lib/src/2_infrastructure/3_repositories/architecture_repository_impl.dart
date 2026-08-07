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
/// lib/src/0_templates/architectures/{id}/arch_definition.yaml を読み込む。
class ArchitectureRepositoryImpl implements ArchitectureRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  /// テンプレートパス解決の上書き(S3: リモートキャッシュ→同梱の順)。
  /// 未指定なら同梱テンプレートのみを見る。
  final Future<String> Function(String relativePath)? _resolveTemplatePath;

  const ArchitectureRepositoryImpl(this._fs, this._yaml,
      {Future<String> Function(String relativePath)? resolveTemplatePath})
      : _resolveTemplatePath = resolveTemplatePath;

  Future<String> _resolve(String relativePath) {
    final resolver = _resolveTemplatePath;
    if (resolver != null) return resolver(relativePath);
    return _fs.resolvePackageTemplatePath(relativePath);
  }

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
        // ローカル上書きが壊れている場合は同梱テンプレートへフォールバックする
        // (ローカルカスタムは任意であり、構文エラーは致命的にしない)。
        try {
          final doc = _yaml.parse(localContent, source: localPath);
          final definition = _parseDefinition(doc);
          if (definition.id == architectureId) {
            return definition;
          }
        } on YamlParseException {
          // fallthrough to package template
        }
      }
    }

    final templateBase = await _resolve(
      p.join('architectures', architectureId, 'arch_definition.yaml'),
    );

    final content = await _fs.readFile(templateBase);
    if (content == null) {
      throw ArchitectureNotFoundException(architectureId);
    }

    // 同梱テンプレートの構文エラーはパッケージ側の不整合であり握りつぶさない
    final doc = _yaml.parse(content, source: templateBase);
    return _parseDefinition(doc);
  }

  @override
  Future<List<ArchitectureDefinitionEntity>> getAll() async {
    // 同梱とリモートキャッシュ(あれば)の両方を列挙し、id で重複排除する
    // (getById は remote-first で解決するため、重複時はリモート定義が勝つ)。
    final roots = <String>{
      await _fs.resolvePackageTemplatePath('architectures'),
      await _resolve('architectures'),
    };
    final ids = <String>{};
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entry in dir.listSync().whereType<Directory>()) {
        ids.add(p.basename(entry.path));
      }
    }

    final result = <ArchitectureDefinitionEntity>[];
    for (final id in ids.toList()..sort()) {
      try {
        result.add(await getById(id));
      } on UtakataDomainException catch (e) {
        // 壊れた定義はスキップするが、黙殺せず stderr に警告する(P6)
        stderr.writeln('⚠️  Skipping broken architecture "$id": $e');
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
      importRules: _parseImportRules(doc['import_rules']),
    );
  }

  /// `import_rules` セクション(Issue #20)をパースする。無ければ null。
  ///
  /// eject した定義の手編集を想定し、型が想定と違う値(リストであるべき所に
  /// スカラ等)はクラッシュせず無視する(壊れた値 = 未指定と同じ扱い)。
  static ImportRuleSet? _parseImportRules(Object? node) {
    if (node is! Map) return null;

    List<String> stringList(Object? value) =>
        value is List ? value.map((e) => e.toString()).toList() : const [];

    final internal = <InternalImportRule>[];
    final internalList = node['internal'];
    if (internalList is List) {
      for (final ruleMap in internalList) {
        if (ruleMap is! Map) continue;
        final dirPattern = ruleMap['dir_pattern'];
        if (dirPattern is! String || dirPattern.isEmpty) continue;
        internal.add(InternalImportRule(
          dirPattern: dirPattern,
          allow: stringList(ruleMap['allow']),
        ));
      }
    }

    final external = <ExternalImportRule>[];
    final externalList = node['external'];
    if (externalList is List) {
      for (final ruleMap in externalList) {
        if (ruleMap is! Map) continue;
        final dirPattern = ruleMap['dir_pattern'];
        if (dirPattern is! String || dirPattern.isEmpty) continue;
        external.add(ExternalImportRule(
          dirPattern: dirPattern,
          deny: stringList(ruleMap['deny']),
        ));
      }
    }

    return ImportRuleSet(
      internalRules: internal,
      externalRules: external,
      excludePatterns: stringList(node['exclude']),
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
        try {
          final doc = _yaml.parse(localContent, source: localPath);
          final definition = _parseDefinition(doc);
          if (definition.id == architectureId) {
            return localContent;
          }
        } on YamlParseException {
          // fallthrough to package template
        }
      }
    }

    final templateBase = await _resolve(
      p.join('architectures', architectureId, 'arch_definition.yaml'),
    );

    final content = await _fs.readFile(templateBase);
    if (content == null) {
      throw ArchitectureNotFoundException(architectureId);
    }

    return content;
  }
}


