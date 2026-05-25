import 'package:yaml/yaml.dart';
import 'package:utakata/utakata.dart';
import '../../1_domain/1_entities/validation_result_entity.dart';
import '../../1_domain/2_repositories/yaml_parser_repository.dart';

/// YAML パーサーリポジトリの実装
///
/// package:yaml を使った YAML パースを Infrastructure 層で実装する。
class YamlParserRepositoryImpl implements YamlParserRepository {
  const YamlParserRepositoryImpl();

  @override
  ValidationResultEntity parse(String yamlStr) {
    try {
      final doc = loadYaml(yamlStr);
      if (doc == null || doc is! Map) {
        return ValidationResultEntity(
          yamlContent: yamlStr,
          isValid: false,
          errorMessage: '不正な YAML 構造です。ルートは Map である必要があります。',
        );
      }
      return ValidationResultEntity(
        yamlContent: yamlStr,
        isValid: true,
        layers: _parseLayers(doc),
        namingRules: _parseNamingRules(doc),
        coreModules: _parseCoreModules(doc),
        guides: _parseGuides(doc),
      );
    } catch (e) {
      return ValidationResultEntity(
        yamlContent: yamlStr,
        isValid: false,
        errorMessage: '構文エラー:\n$e',
      );
    }
  }

  List<LayerDefinitionEntity> _parseLayers(Map doc) {
    final list = doc['layers'];
    if (list is! List) return [];
    return list.whereType<Map>().map((m) => LayerDefinitionEntity(
          name: m['name'] as String? ?? '',
          dirs: (m['dirs'] as List?)?.map((d) => d.toString()).toList() ?? [],
        )).toList();
  }

  List<NamingRuleEntity> _parseNamingRules(Map doc) {
    final list = doc['naming_rules'];
    if (list is! List) return [];
    return list.whereType<Map>().map((m) => NamingRuleEntity(
          dirPattern: m['dir_pattern'] as String? ?? '',
          filePattern: m['file_pattern'] as String? ?? '',
          description: m['description'] as String? ?? '',
        )).toList();
  }

  List<CoreModuleEntity> _parseCoreModules(Map doc) {
    final list = doc['core_modules'];
    if (list is! List) return [];
    return list.whereType<Map>().where((m) {
      final id = m['id'] as String? ?? '';
      final path = m['path'] as String? ?? '';
      return id.isNotEmpty && path.isNotEmpty;
    }).map((m) => CoreModuleEntity(
          id: m['id'] as String,
          path: m['path'] as String,
          displayName: m['displayName'] as String? ?? '',
        )).toList();
  }

  List<GuideEntity> _parseGuides(Map doc) {
    final list = doc['guides'];
    if (list is! List) return [];
    return list.whereType<Map>().map((m) => GuideEntity(
          title: m['title'] as String? ?? '',
          layerPath: m['layer_path'] as String? ?? '',
          applyTo: m['apply_to'] as String? ?? '',
          doList: (m['do_list'] as List?)?.map((e) => e.toString()).toList() ?? [],
          dontList: (m['dont_list'] as List?)?.map((e) => e.toString()).toList() ?? [],
          allowedImports: (m['allowed_imports'] as List?)?.map((e) => e.toString()).toList() ?? [],
          forbiddenImports: (m['forbidden_imports'] as List?)?.map((e) => e.toString()).toList() ?? [],
          namingPattern: m['naming_pattern'] as String? ?? '',
          detailContentPath: m['detail_content_path'] as String? ?? '',
        )).toList();
  }
}
