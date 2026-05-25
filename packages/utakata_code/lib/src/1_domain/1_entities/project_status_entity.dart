/// プロジェクト状態エンティティ
///
/// `project_status.yaml` に対応するデータ構造。
/// `utakata status` 実行時にディスクスキャンで収集し、YAML に書き出す。
class ProjectStatusEntity {
  /// プロジェクト名（pubspec.yaml の name）
  final String projectName;

  /// プロジェクトバージョン（pubspec.yaml の version）
  final String projectVersion;

  /// pubspec.yaml が存在するか
  final bool pubspecExists;

  /// lib/ が存在するか
  final bool libExists;

  /// Flutter プロジェクトとして初期化済みか（pubspec + lib 両方）
  final bool initialized;

  /// コアモジュールの状態マップ（id -> 存在するか）
  final Map<String, bool> coreModules;

  /// lib/main.dart が存在するか
  final bool mainDartExists;

  /// lib/app.dart が存在するか
  final bool appDartExists;

  /// 仕様書の状態（"template_only" | "edited"）
  final String specificationStatus;

  /// 構造計画書の状態（"template_only" | "edited"）
  final String structurePlanStatus;

  /// フィーチャー数
  final int featureCount;

  /// 更新日時
  final DateTime updatedAt;

  const ProjectStatusEntity({
    required this.projectName,
    required this.projectVersion,
    required this.pubspecExists,
    required this.libExists,
    required this.initialized,
    required this.coreModules,
    required this.mainDartExists,
    required this.appDartExists,
    required this.specificationStatus,
    required this.structurePlanStatus,
    required this.featureCount,
    required this.updatedAt,
  });

  /// YAML 書き出し用の Map に変換する
  Map<String, dynamic> toYamlMap() {
    final coreMap = <String, dynamic>{};
    for (final entry in coreModules.entries) {
      coreMap[entry.key] = entry.value;
    }

    return {
      'project': {
        'name': projectName,
        'version': projectVersion,
      },
      'flutter': {
        'pubspec_exists': pubspecExists,
        'lib_exists': libExists,
        'initialized': initialized,
      },
      'core': coreMap,
      'entry_points': {
        'main_dart': mainDartExists,
        'app_dart': appDartExists,
      },
      'documents': {
        'specification': specificationStatus,
        'structure_plan': structurePlanStatus,
      },
      'features': {
        'count': featureCount,
      },
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': 'utakata status',
    };
  }
}
