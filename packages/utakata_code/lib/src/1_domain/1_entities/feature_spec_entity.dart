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

  /// plan.yaml で「不要」と宣言された層パス(Issue #12)。
  /// ここに該当するディレクトリは生成しない。
  final Set<String> optedOutLayers;

  const FeatureSpecEntity({
    required this.featureName,
    required this.entityName,
    required this.permission,
    this.architectureId = 'clean_architecture',
    this.optedOutLayers = const {},
  });

  /// [layerPath] 自体または祖先が不要宣言されているか。
  bool skips(String layerPath) => optedOutLayers.any(
      (opted) => layerPath == opted || layerPath.startsWith('$opted/'));

  /// フィーチャーのベースパス（lib/features/ 以下の相対パス）
  String get relativePath {
    if (permission == 'direct') return 'lib/features/$featureName';
    return 'lib/features/$permission/$featureName';
  }

  @override
  String toString() =>
      'FeatureSpecEntity(feature: $featureName, entity: $entityName, perm: $permission)';
}
