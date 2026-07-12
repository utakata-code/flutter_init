/// 文字列のケース変換を行う純関数サービス
///
/// 従来 create_command / feature_command / add_feature_usecase /
/// create_architecture_usecase の4箇所に重複・不一致(camelCase境界の
/// 分割有無等)して実装されていたものを1実装に統合する。
abstract final class CaseConverter {
  /// "MyFeature" / "my-feature" / "myFeature" などを "my_feature" に変換する
  static String toSnakeCase(String input) {
    final withBoundaries = input.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
      (m) => '_',
    );
    return withBoundaries
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .toLowerCase()
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// "my_feature" / "my-feature" / "my feature" を "MyFeature" に変換する
  static String toPascalCase(String input) {
    return input
        .split(RegExp(r'[-_ ]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join();
  }

  /// "my_feature" / "my-feature" を "myFeature" に変換する
  static String toCamelCase(String input) {
    final pascal = toPascalCase(input);
    if (pascal.isEmpty) return pascal;
    return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
  }
}
