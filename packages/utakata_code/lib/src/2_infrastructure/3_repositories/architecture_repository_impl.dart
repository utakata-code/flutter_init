import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/architecture_definition_entity.dart';
import '../../1_domain/1_entities/core_module_entity.dart';
import '../../1_domain/1_entities/dependency_stack_entity.dart';
import '../../1_domain/1_entities/guide_entity.dart';
import '../../1_domain/2_repositories/architecture_repository.dart';
import '../../1_domain/exceptions/domain_exceptions.dart';
import '../../1_domain/services/name_rule_matcher.dart';
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

    // guides セクションをパース。
    // v2(スリム書式)では layer_path + do/dont だけ書けばよく、
    // 以下は規約から導出する(明示があれば上書き):
    //   apply_to            = lib/features/**/<layer_path>/**
    //   detail_content_path = architectures/<id>/layers/features/<layer_path>/GUIDE.md
    //   naming_pattern      = naming_rules の該当 description
    //   title               = layer_path
    final archId = doc['id'] as String? ?? '';
    final guides = <GuideEntity>[];
    final guidesList = doc['guides'];
    if (guidesList is List) {
      for (final guideMap in guidesList) {
        if (guideMap is Map) {
          final layerPath = guideMap['layer_path'] as String? ?? '';
          List<String> stringList(Object? v) =>
              v is List ? v.map((e) => e.toString()).toList() : const [];

          final doList = guideMap.containsKey('do')
              ? stringList(guideMap['do'])
              : stringList(guideMap['do_list']);
          final dontList = guideMap.containsKey('dont')
              ? stringList(guideMap['dont'])
              : stringList(guideMap['dont_list']);

          final explicitApplyTo = guideMap['apply_to'] as String? ?? '';
          final explicitDetail =
              guideMap['detail_content_path'] as String? ?? '';
          final explicitNaming = guideMap['naming_pattern'] as String? ?? '';
          final explicitTitle = guideMap['title'] as String? ?? '';

          guides.add(GuideEntity(
            title: explicitTitle.isNotEmpty ? explicitTitle : layerPath,
            layerPath: layerPath,
            applyTo: explicitApplyTo.isNotEmpty
                ? explicitApplyTo
                : 'lib/features/**/$layerPath/**',
            doList: doList,
            dontList: dontList,
            allowedImports: stringList(guideMap['allowed_imports']),
            forbiddenImports: stringList(guideMap['forbidden_imports']),
            namingPattern: explicitNaming.isNotEmpty
                ? explicitNaming
                : (NameRuleMatcher.findFor(layerPath, namingRules)
                        ?.description ??
                    ''),
            detailContentPath: explicitDetail.isNotEmpty
                ? explicitDetail
                : 'architectures/$archId/layers/features/$layerPath/GUIDE.md',
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
  /// v2(`layers:` 層グラフ + `dirs:` 細則)と v1(`internal:` + `external:`)の
  /// 両書式を読める。eject した定義の手編集を想定し、型が想定と違う値
  /// (リストであるべき所にスカラ等)はクラッシュせず無視する。
  static ImportRuleSet? _parseImportRules(Object? node) {
    if (node is! Map) return null;

    List<String> stringList(Object? value) =>
        value is List ? value.map((e) => e.toString()).toList() : const [];

    List<InternalImportRule> parseDirRules(Object? list) {
      final rules = <InternalImportRule>[];
      if (list is List) {
        for (final ruleMap in list) {
          if (ruleMap is! Map) continue;
          final dirPattern = ruleMap['dir_pattern'];
          if (dirPattern is! String || dirPattern.isEmpty) continue;
          rules.add(InternalImportRule(
            dirPattern: dirPattern,
            allow: stringList(ruleMap['allow']),
          ));
        }
      }
      return rules;
    }

    // v2: 層間依存グラフ
    final layerGraph = <String, List<String>>{};
    final layersNode = node['layers'];
    if (layersNode is Map) {
      for (final entry in layersNode.entries) {
        layerGraph[entry.key.toString()] = stringList(entry.value);
      }
    }

    // v2 の `dirs:` と v1 の `internal:` は同じ形(併記されたら両方有効)
    final internal = [
      ...parseDirRules(node['dirs']),
      ...parseDirRules(node['internal']),
    ];

    // v1 の deny ブラックリスト(後方互換)
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
      layerGraph: layerGraph,
      internalRules: internal,
      externalRules: external,
      excludePatterns: stringList(node['exclude']),
    );
  }

  @override
  Future<DependencyStack> getDependencyStack(String architectureId) async {
    // dependencies/*.yaml(v2: バージョン + 配置宣言)を読む
    final depsDir = await _resolve(
      p.join('architectures', architectureId, 'dependencies'),
    );
    final dir = Directory(depsDir);
    if (dir.existsSync()) {
      var dependencies = <String, dynamic>{};
      var devDependencies = <String, dynamic>{};
      final placements = <PackagePlacement>[];

      final yamlFiles = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in yamlFiles) {
        final content = await _fs.readFile(file.path);
        if (content == null) continue;
        final Map<String, dynamic> doc;
        try {
          doc = _yaml.parse(content, source: file.path);
        } on YamlParseException {
          stderr.writeln('⚠️  Skipping broken dependency stack: ${file.path}');
          continue;
        }

        final isCoreStack = p.basename(file.path) == 'core_stack.yaml';
        final parsed = _parseStackSection(doc['dependencies']);
        final parsedDev = _parseStackSection(doc['dev_dependencies']);
        placements.addAll(parsed.placements);
        if (isCoreStack) {
          dependencies = parsed.pubspecValues;
          devDependencies = parsedDev.pubspecValues;
        }
      }

      if (dependencies.isNotEmpty ||
          devDependencies.isNotEmpty ||
          placements.isNotEmpty) {
        return DependencyStack(
          dependencies: dependencies,
          devDependencies: devDependencies,
          placements: placements,
        );
      }
    }

    // 旧構成へフォールバック: 定義内の dependencies/dev_dependencies(v1)
    final arch = await getById(architectureId);
    return DependencyStack(
      dependencies: arch.dependencies,
      devDependencies: arch.devDependencies,
    );
  }

  /// スタック yaml の 1 セクション(dependencies / dev_dependencies)をパースする。
  ///
  /// エントリの値は次のどちらでもよい:
  /// - スカラ(v1 互換): `dio: ^5.7.0` → pubspec 値そのまま。配置制約なし
  /// - マップ(v2): `version:` / `sdk:` が pubspec 値、`layers:` が配置宣言
  static ({Map<String, dynamic> pubspecValues, List<PackagePlacement> placements})
      _parseStackSection(Object? node) {
    final pubspecValues = <String, dynamic>{};
    final placements = <PackagePlacement>[];
    if (node is Map) {
      for (final entry in node.entries) {
        final name = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          if (value.containsKey('sdk')) {
            pubspecValues[name] = {'sdk': value['sdk']};
          } else if (value['version'] != null) {
            pubspecValues[name] = value['version'].toString();
          }
          final layers = value['layers'];
          if (layers is List) {
            placements.add(PackagePlacement(
              package: name,
              layers: layers.map((e) => e.toString()).toList(),
            ));
          }
        } else if (value != null) {
          pubspecValues[name] = value;
        }
      }
    }
    return (pubspecValues: pubspecValues, placements: placements);
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


