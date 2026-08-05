import 'dart:io' show stderr;

import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/plan/plan_intent.dart';
import '../../1_domain/2_repositories/config_repository.dart';
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
///
/// アーキテクチャの既定値は `utakata.yaml`(マスター設定)が plan.yaml より
/// 優先される(実装計画 D6)。両方に明示され食い違う場合は stderr に警告する。
class PlanRepositoryImpl implements PlanRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;
  final YamlEditDataSource _yamlEdit;
  final ConfigRepository? _configRepo;

  const PlanRepositoryImpl(this._fs, this._yaml, this._yamlEdit,
      {ConfigRepository? configRepo})
      : _configRepo = configRepo;

  static const _planYamlPath = 'doc/specs/plan.yaml';
  static const _legacyFeatureRequestPath = 'AI/specs/feature_request.yaml';

  @override
  Future<PlanIntent?> read(String projectDir) async {
    final planPath = p.join(projectDir, _planYamlPath);
    final planContent = await _fs.readFile(planPath);
    if (planContent != null) {
      final doc = _yaml.parse(planContent, source: planPath);
      final project = doc['project'];
      final planSpecifiesArch = project is Map && project['architecture'] != null;
      return _applyConfigOverride(
        projectDir,
        PlanIntent.fromMap(doc),
        planSpecifiesArch: planSpecifiesArch,
      );
    }

    final legacyPath = p.join(projectDir, _legacyFeatureRequestPath);
    final legacyContent = await _fs.readFile(legacyPath);
    if (legacyContent != null) {
      final doc = _yaml.parse(legacyContent, source: legacyPath);
      return _fromLegacyFeatureRequest(doc);
    }

    return null;
  }

  /// `utakata.yaml` の `project.architecture` が指定されていれば plan の既定値を
  /// 上書きする。plan.yaml 側にも明示されていて食い違う場合のみ警告する
  /// (plan 側が省略されている場合は正当な「マスター設定からの継承」)。
  Future<PlanIntent> _applyConfigOverride(
    String projectDir,
    PlanIntent intent, {
    required bool planSpecifiesArch,
  }) async {
    final config = await _configRepo?.read(projectDir);
    final configArch = config?.architecture;
    if (configArch == null || configArch.isEmpty) return intent;

    if (planSpecifiesArch && intent.defaultArchitectureId != configArch) {
      stderr.writeln('⚠️  utakata.yaml (architecture: $configArch) と '
          'doc/specs/plan.yaml (architecture: ${intent.defaultArchitectureId}) が'
          '食い違っています。utakata.yaml を優先します。plan.yaml 側の指定は削除を推奨。');
    }

    return PlanIntent(
      schema: intent.schema,
      defaultArchitectureId: configArch,
      features: intent.features,
    );
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
  Future<bool> setLayerDeclarations(
    String projectDir,
    String featureName,
    Map<String, List<String>> declarations,
  ) async {
    if (declarations.isEmpty) return true;

    final path = p.join(projectDir, _planYamlPath);
    final existing = await _fs.readFile(path);
    if (existing == null) return false;

    final index = _yamlEdit.indexOfFeature(existing, featureName);
    if (index < 0) return false;

    // `layers` が未作成なら Map ごと1回で書く(ブロックスタイルになり人間が
    // 編集しやすい)。既にある場合はキー単位で更新し、利用者が書いた
    // コメント・並びを壊さない。
    final hasLayers =
        _yamlEdit.hasNode(existing, ['features', index, 'layers']);
    if (!hasLayers) {
      final updated = _yamlEdit
          .setAt(existing, ['features', index, 'layers'], declarations);
      await _fs.writeFile(path, updated);
      return true;
    }

    var content = existing;
    for (final entry in declarations.entries) {
      content = _yamlEdit.setAt(
        content,
        ['features', index, 'layers', entry.key],
        entry.value,
      );
    }
    await _fs.writeFile(path, content);
    return true;
  }

  @override
  Future<bool> removeLayerItem(
    String projectDir,
    String featureName,
    String layerPath,
    String item,
  ) async {
    final path = p.join(projectDir, _planYamlPath);
    final existing = await _fs.readFile(path);
    if (existing == null) return false;

    final index = _yamlEdit.indexOfFeature(existing, featureName);
    if (index < 0) return false;

    final updated = _yamlEdit.removeFromList(
      existing,
      ['features', index, 'layers', layerPath],
      item,
    );
    if (identical(updated, existing) || updated == existing) return false;
    await _fs.writeFile(path, updated);
    return true;
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
