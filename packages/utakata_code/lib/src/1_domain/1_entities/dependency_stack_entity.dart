/// 外部依存スタック(`arches/<id>/dependencies/*.yaml`)のエンティティ群。
///
/// arch_definition.yaml から外部依存の管理を分離したもの(v1.5.0)。
/// 1パッケージにつき「バージョン」と「使ってよい層(配置宣言)」を1箇所で持つ。
library;

/// パッケージ1件の配置宣言。
///
/// - [layers] が **null**(キー省略)→ 配置制約なし(どの層でも import 可)
/// - [layers] が **空リスト** → どの層でも import しない
///   (build 時のみ必要な依存。例: sqlite3_flutter_libs)
/// - [layers] に層パスあり → その層でのみ import 可
///
/// スタックに**宣言されていない**パッケージは監査で論じない(すべて許可)。
final class PackagePlacement {
  final String package;
  final List<String>? layers;

  const PackagePlacement({required this.package, this.layers});

  bool get isConstrained => layers != null;
}

/// アーキテクチャの外部依存スタック全体。
final class DependencyStack {
  /// pubspec の dependencies に入れる値(package → バージョン文字列 or `{sdk: flutter}`)。
  /// `utakata create` が初期 pubspec に反映する(core_stack.yaml 由来)。
  final Map<String, dynamic> dependencies;

  /// pubspec の dev_dependencies に入れる値。
  final Map<String, dynamic> devDependencies;

  /// 配置宣言(`utakata imports` が検証)。core_stack 以外の
  /// `dependencies/*.yaml`(recommended 等)の宣言も含む。
  final List<PackagePlacement> placements;

  const DependencyStack({
    this.dependencies = const {},
    this.devDependencies = const {},
    this.placements = const [],
  });

  static const empty = DependencyStack();

  bool get isEmpty =>
      dependencies.isEmpty && devDependencies.isEmpty && placements.isEmpty;
}
