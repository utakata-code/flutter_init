/// テンプレートファイルエンティティ
///
/// テンプレートとして展開されるファイルの定義。
/// パスとコンテンツは {{...}} 形式のプレースホルダーを含む。
///
/// プレースホルダー仕様:
///   {{entity_name}}   → snake_case のエンティティ名
///   {{EntityName}}    → PascalCase のエンティティ名
///   {{entityName}}    → camelCase のエンティティ名
///   {{feature_name}}  → snake_case のフィーチャー名
///   {{FeatureName}}   → PascalCase のフィーチャー名
///   {{permission}}    → 権限レベル
class TemplateFileEntity {
  /// 展開先の相対パス（プレースホルダー含む）
  /// 例: '{{feature_name}}/1_domain/1_entities/{{entity_name}}_entity.dart'
  final String relativePath;

  /// ファイルの内容（プレースホルダー含む）
  final String content;

  const TemplateFileEntity({
    required this.relativePath,
    required this.content,
  });

  /// プレースホルダーを実際の値に置換したパスを返す
  String resolvedPath(Map<String, String> variables) =>
      _resolve(relativePath, variables);

  /// プレースホルダーを実際の値に置換したコンテンツを返す
  String resolvedContent(Map<String, String> variables) =>
      _resolve(content, variables);

  /// {{key}} を variables[key] に置換する
  String _resolve(String template, Map<String, String> variables) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  @override
  String toString() => 'TemplateFileEntity(path: $relativePath)';
}
