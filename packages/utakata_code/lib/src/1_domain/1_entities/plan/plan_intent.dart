/// `doc/specs/plan.yaml`(意図レベル計画。仕様書 §6)の1 feature 分の宣言。
///
/// 旧 `plan_architecture.yaml` のような具象ディレクトリツリーを永続化せず、
/// 「何を作りたいか」だけを人間/AI が書く。具象構造は
/// [ExpectedStructureBuilder](../../services/expected_structure_builder.dart)が
/// アーキテクチャ定義と組み合わせて毎回導出する。
final class PlanFeatureIntent {
  final String name;
  final String permission; // admin | user | shared | direct
  final List<String> entities;

  /// feature 単位のアーキテクチャ上書き(未指定なら project 既定を使う)
  final String? architectureId;

  /// 初回一括生成(apply --scope feature の初回実行)で自動付与される。
  /// 実装計画ゲート(v0.9)の免除マーカーとして使う。
  final bool baseline;

  const PlanFeatureIntent({
    required this.name,
    required this.permission,
    this.entities = const [],
    this.architectureId,
    this.baseline = false,
  });

  factory PlanFeatureIntent.fromMap(Map<String, dynamic> map) {
    final rawEntities = map['entities'];
    return PlanFeatureIntent(
      name: map['name'] as String,
      permission: (map['permission'] as String?) ?? 'user',
      entities: rawEntities is List
          ? rawEntities.map((e) => e.toString()).toList()
          : const [],
      architectureId: map['architecture'] as String?,
      baseline: (map['baseline'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'permission': permission,
        if (entities.isNotEmpty) 'entities': entities,
        if (architectureId != null) 'architecture': architectureId,
        if (baseline) 'baseline': true,
      };
}

final class PlanIntent {
  static const currentSchema = 1;

  final int schema;
  final String defaultArchitectureId;
  final List<PlanFeatureIntent> features;

  const PlanIntent({
    this.schema = currentSchema,
    required this.defaultArchitectureId,
    required this.features,
  });

  factory PlanIntent.fromMap(Map<String, dynamic> map) {
    final project = map['project'];
    final defaultArch = (project is Map)
        ? (project['architecture'] as String?) ?? 'clean_architecture'
        : 'clean_architecture';
    final rawFeatures = map['features'];
    final features = rawFeatures is List
        ? rawFeatures
            .whereType<Map>()
            .map((m) => PlanFeatureIntent.fromMap(Map<String, dynamic>.from(m)))
            .toList()
        : <PlanFeatureIntent>[];
    return PlanIntent(
      schema: (map['schema'] as int?) ?? currentSchema,
      defaultArchitectureId: defaultArch,
      features: features,
    );
  }

  Map<String, dynamic> toMap() => {
        'schema': schema,
        'project': {'architecture': defaultArchitectureId},
        'features': features.map((f) => f.toMap()).toList(),
      };

  PlanIntent addFeature(PlanFeatureIntent feature) =>
      PlanIntent(
        schema: schema,
        defaultArchitectureId: defaultArchitectureId,
        features: [...features, feature],
      );
}
