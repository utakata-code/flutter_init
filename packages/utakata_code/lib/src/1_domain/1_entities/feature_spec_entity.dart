/// フィーチャー仕様エンティティ
///
/// utakata feature add コマンドで収集するフィーチャーの仕様を表す。
class FeatureSpecEntity {
  /// フィーチャー名（snake_case）
  final String featureName;

  /// エンティティ名（snake_case）。デフォルトは featureName と同じ
  final String entityName;

  /// 権限レベル（'user' | 'admin' | 'shared' | 'direct'）
  final String permission;

  /// 使用するアーキテクチャの識別子
  final String architectureId;

  const FeatureSpecEntity({
    required this.featureName,
    required this.entityName,
    required this.permission,
    this.architectureId = 'clean_architecture',
  });

  /// featureName と entityName が一致しているか
  bool get isEntitySameAsFeature => featureName == entityName;

  /// フィーチャーのベースパス（lib/features/ 以下の相対パス）
  String get relativePath {
    if (permission == 'direct') return 'lib/features/$featureName';
    return 'lib/features/$permission/$featureName';
  }

  @override
  String toString() =>
      'FeatureSpecEntity(feature: $featureName, entity: $entityName, perm: $permission)';
}
