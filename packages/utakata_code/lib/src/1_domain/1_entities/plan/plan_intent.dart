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

  /// 層ごとの明示宣言(Issue #12)。キーはアーキテクチャ定義の層パス
  /// (例: `1_domain/3_usecases`)、値はその層に置く項目名のリスト。
  ///
  /// - **キーが無い** → 従来どおり `entities` から導出する(自動生成が基準)
  /// - **項目リストあり** → その項目だけを必須とする(手動での増減)
  /// - **空リスト `[]`** → その層は不要と明示する(配下ごと対象外)
  ///
  /// これにより「feature を1つ宣言すると全層が計画済みになる」問題を解消しつつ、
  /// 何も書かなければ従来の挙動を保つ。
  final Map<String, List<String>> layers;

  const PlanFeatureIntent({
    required this.name,
    required this.permission,
    this.entities = const [],
    this.architectureId,
    this.baseline = false,
    this.layers = const {},
  });

  factory PlanFeatureIntent.fromMap(Map<String, dynamic> map) {
    final rawEntities = map['entities'];
    final rawLayers = map['layers'];
    final layers = <String, List<String>>{};
    if (rawLayers is Map) {
      for (final entry in rawLayers.entries) {
        final value = entry.value;
        layers[entry.key.toString()] = value is List
            ? value.map((e) => e.toString()).toList()
            : const <String>[];
      }
    }
    return PlanFeatureIntent(
      name: map['name'] as String,
      permission: (map['permission'] as String?) ?? 'user',
      entities: rawEntities is List
          ? rawEntities.map((e) => e.toString()).toList()
          : const [],
      architectureId: map['architecture'] as String?,
      baseline: (map['baseline'] as bool?) ?? false,
      layers: layers,
    );
  }

  /// [layerPath] に対する宣言を返す。宣言が無ければ null(= 自動導出)。
  List<String>? declarationFor(String layerPath) => layers[layerPath];

  /// [layerPath] またはその祖先が空リストで宣言されているか(対象外の層か)。
  bool isOptedOut(String layerPath) {
    for (final entry in layers.entries) {
      if (entry.value.isNotEmpty) continue;
      if (layerPath == entry.key || layerPath.startsWith('${entry.key}/')) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'permission': permission,
        if (entities.isNotEmpty) 'entities': entities,
        if (architectureId != null) 'architecture': architectureId,
        if (baseline) 'baseline': true,
        if (layers.isNotEmpty) 'layers': layers,
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
