/// feature プリセットテンプレートの1件分の宣言(仕様書 §10)。
final class FeatureTemplateManifest {
  final String id;
  final String permission;
  final List<String> entities;

  const FeatureTemplateManifest({
    required this.id,
    required this.permission,
    this.entities = const [],
  });
}

/// feature プリセットテンプレートを解決するリポジトリのインターフェース。
///
/// 解決順は project → `~/.utakata/feature_templates/` → パッケージ内蔵
/// (v1.0 時点ではメカニズムのみで内蔵コンテンツは同梱しない)。
abstract interface class FeatureTemplateRepository {
  Future<FeatureTemplateManifest?> resolve(String projectDir, String templateId);
}
