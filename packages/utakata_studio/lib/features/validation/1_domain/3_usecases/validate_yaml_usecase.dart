import 'package:yaml/yaml.dart';
import 'package:utakata/utakata.dart';

import '../../1_domain/1_entities/yaml_validation_result_entity.dart';

/// YAML バリデーションのユースケース
///
/// 文字列を受け取り、パース → 層構造・命名規則・コアモジュールの抽出 → 結果返却を行う。
class ValidateYamlUsecase {
  const ValidateYamlUsecase();

  YamlValidationResult execute(String yamlStr) {
    if (yamlStr.trim().isEmpty) {
      return const YamlValidationResult(
        yamlContent: '',
        isValid: false,
        errorMessage: 'YAML が空です。',
      );
    }

    try {
      final doc = loadYaml(yamlStr);
      if (doc == null || doc is! Map) {
        return YamlValidationResult(
          yamlContent: yamlStr,
          isValid: false,
          errorMessage: '不正な YAML 構造です。ルートは Map である必要があります。',
        );
      }

      final layers = _parseLayers(doc);
      final namingRules = _parseNamingRules(doc);
      final coreModules = _parseCoreModules(doc);
      final guides = _parseGuides(doc);

      return YamlValidationResult(
        yamlContent: yamlStr,
        isValid: true,
        layers: layers,
        namingRules: namingRules,
        coreModules: coreModules,
        guides: guides,
      );
    } catch (e) {
      return YamlValidationResult(
        yamlContent: yamlStr,
        isValid: false,
        errorMessage: '構文エラー:\n$e',
      );
    }
  }

  List<LayerDefinitionEntity> _parseLayers(Map doc) {
    final layers = <LayerDefinitionEntity>[];
    final list = doc['layers'];
    if (list is List) {
      for (final m in list) {
        if (m is Map) {
          layers.add(LayerDefinitionEntity(
            name: m['name'] as String? ?? '',
            dirs: (m['dirs'] as List?)?.map((d) => d.toString()).toList() ?? [],
          ));
        }
      }
    }
    return layers;
  }

  List<NamingRuleEntity> _parseNamingRules(Map doc) {
    final rules = <NamingRuleEntity>[];
    final list = doc['naming_rules'];
    if (list is List) {
      for (final m in list) {
        if (m is Map) {
          rules.add(NamingRuleEntity(
            dirPattern: m['dir_pattern'] as String? ?? '',
            filePattern: m['file_pattern'] as String? ?? '',
            description: m['description'] as String? ?? '',
          ));
        }
      }
    }
    return rules;
  }

  List<CoreModuleEntity> _parseCoreModules(Map doc) {
    final modules = <CoreModuleEntity>[];
    final list = doc['core_modules'];
    if (list is List) {
      for (final m in list) {
        if (m is Map) {
          final id = m['id'] as String? ?? '';
          final path = m['path'] as String? ?? '';
          if (id.isNotEmpty && path.isNotEmpty) {
            modules.add(CoreModuleEntity(
              id: id,
              path: path,
              displayName: m['displayName'] as String? ?? '',
            ));
          }
        }
      }
    }
    return modules;
  }

  List<GuideEntity> _parseGuides(Map doc) {
    final guides = <GuideEntity>[];
    final list = doc['guides'];
    if (list is List) {
      for (final m in list) {
        if (m is Map) {
          guides.add(GuideEntity(
            title: m['title'] as String? ?? '',
            layerPath: m['layer_path'] as String? ?? '',
            applyTo: m['apply_to'] as String? ?? '',
            doList: (m['do_list'] as List?)?.map((e) => e.toString()).toList() ?? [],
            dontList: (m['dont_list'] as List?)?.map((e) => e.toString()).toList() ?? [],
            allowedImports: (m['allowed_imports'] as List?)?.map((e) => e.toString()).toList() ?? [],
            forbiddenImports: (m['forbidden_imports'] as List?)?.map((e) => e.toString()).toList() ?? [],
            namingPattern: m['naming_pattern'] as String? ?? '',
            detailContentPath: m['detail_content_path'] as String? ?? '',
          ));
        }
      }
    }
    return guides;
  }
}
