import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/plan/plan_intent.dart';
import '../../1_domain/2_repositories/plan_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';
import '../2_data_sources/1_local/yaml_edit_data_source.dart';

/// [PlanRepository] の実装。
///
/// `doc/specs/plan.yaml` を優先して読み、無ければ旧
/// `AI/specs/feature_request.yaml`(feature 名をキーにした Map 形式)を
/// 読み取り専用でフォールバック解釈する。フォールバック時は
/// ファイルへの書き戻しを一切行わない(v0.7 の後方互換; 仕様書 §6)。
class PlanRepositoryImpl implements PlanRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;
  final YamlEditDataSource _yamlEdit;

  const PlanRepositoryImpl(this._fs, this._yaml, this._yamlEdit);

  static const _planYamlPath = 'doc/specs/plan.yaml';
  static const _legacyFeatureRequestPath = 'AI/specs/feature_request.yaml';

  @override
  Future<PlanIntent?> read(String projectDir) async {
    final planPath = p.join(projectDir, _planYamlPath);
    final planContent = await _fs.readFile(planPath);
    if (planContent != null) {
      final doc = _yaml.parse(planContent, source: planPath);
      return PlanIntent.fromMap(doc);
    }

    final legacyPath = p.join(projectDir, _legacyFeatureRequestPath);
    final legacyContent = await _fs.readFile(legacyPath);
    if (legacyContent != null) {
      final doc = _yaml.parse(legacyContent, source: legacyPath);
      return _fromLegacyFeatureRequest(doc);
    }

    return null;
  }

  /// 旧 `feature_request.yaml`({featureName: {entity, permission, architecture}})
  /// を意図レベルの [PlanIntent] へ変換する(その場限りの変換。永続化しない)。
  PlanIntent _fromLegacyFeatureRequest(Map<String, dynamic> doc) {
    final projectNode = doc['project'];
    final defaultArch = (projectNode is Map)
        ? (projectNode['architecture'] as String?) ?? 'clean_architecture'
        : 'clean_architecture';

    final featuresNode = doc['features'];
    final features = <PlanFeatureIntent>[];
    if (featuresNode is Map) {
      for (final entry in featuresNode.entries) {
        final name = entry.key as String;
        final details = entry.value;
        var entity = name;
        var permission = 'user';
        String? archId;
        if (details is Map) {
          entity = (details['entity'] as String?) ?? name;
          permission = (details['permission'] as String?) ?? 'user';
          archId = details['architecture'] as String?;
        }
        features.add(PlanFeatureIntent(
          name: name,
          permission: permission,
          entities: [entity],
          architectureId: archId,
          baseline: true,
        ));
      }
    }
    return PlanIntent(defaultArchitectureId: defaultArch, features: features);
  }

  @override
  Future<void> write(String projectDir, PlanIntent plan) async {
    final path = p.join(projectDir, _planYamlPath);
    await _fs.writeFile(path, _yamlEdit.render(plan.toMap()));
  }

  @override
  Future<void> adoptFeature(String projectDir, PlanFeatureIntent feature) async {
    final path = p.join(projectDir, _planYamlPath);
    final existing = await _fs.readFile(path);
    if (existing == null) {
      final fresh = PlanIntent(
        defaultArchitectureId: feature.architectureId ?? 'clean_architecture',
        features: [feature],
      );
      await _fs.writeFile(path, _yamlEdit.render(fresh.toMap()));
      return;
    }
    final updated = _yamlEdit.appendToList(existing, ['features'], feature.toMap());
    await _fs.writeFile(path, updated);
  }
}
