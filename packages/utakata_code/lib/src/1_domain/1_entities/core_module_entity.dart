/// コアモジュールエンティティ
///
/// アーキテクチャ定義 YAML の `core_modules` セクションから読み込まれる、
/// プロジェクト生成時のステータス追跡対象モジュールの定義。
class CoreModuleEntity {
  /// モジュールの識別子（例: 'routing', 'theme'）
  final String id;

  /// ディレクトリの相対パス（例: 'lib/core/routing'）
  final String path;

  /// 画面上の表示名（例: 'routing/'）
  final String displayName;

  const CoreModuleEntity({
    required this.id,
    required this.path,
    required this.displayName,
  });

  @override
  String toString() => 'CoreModuleEntity(id: $id, path: $path, displayName: $displayName)';
}
