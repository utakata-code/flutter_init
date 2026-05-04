library;

/// utakata ドメイン層の例外クラス群
///
/// 例外メッセージは言語非依存の英語で記述する。
/// ユーザー向けの多言語メッセージは CliMessages 経由で Command 層が担う。
sealed class UtakataDomainException implements Exception {
  final String message;
  const UtakataDomainException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// 指定したアーキテクチャが存在しない
final class ArchitectureNotFoundException extends UtakataDomainException {
  const ArchitectureNotFoundException(String architectureId)
      : super('Architecture "$architectureId" not found.');
}

/// 指定したテンプレートが存在しない
final class TemplateNotFoundException extends UtakataDomainException {
  const TemplateNotFoundException(String templateId)
      : super('Template "$templateId" not found.');
}

/// feature_request.yaml が存在しない
final class FeatureRequestNotFoundException extends UtakataDomainException {
  const FeatureRequestNotFoundException(String path)
      : super('feature_request.yaml not found: $path');
}

/// plan_architecture.yaml が存在しない
final class PlanArchitectureNotFoundException extends UtakataDomainException {
  const PlanArchitectureNotFoundException(String path)
      : super('plan_architecture.yaml not found: $path. Run `utakata plan` first.');
}

/// プロジェクトディレクトリが Flutter プロジェクトでない
final class NotFlutterProjectException extends UtakataDomainException {
  const NotFlutterProjectException(String dir)
      : super('"$dir" is not a Flutter project root.');
}

/// フィーチャー名が不正
final class InvalidFeatureNameException extends UtakataDomainException {
  const InvalidFeatureNameException(String name)
      : super('Invalid feature name "$name". Use snake_case.');
}

/// flutter コマンドが見つからない
///
/// FLUTTER_PATH / FLUTTER_ROOT 環境変数、または PATH 上に
/// flutter 実行ファイルが存在しない場合にスローされる。
final class FlutterNotFoundException extends UtakataDomainException {
  const FlutterNotFoundException()
      : super(
          'flutter command not found. '
          'Set FLUTTER_PATH environment variable to the full path.',
        );
}

/// YAML 解析に失敗した
final class YamlParseException extends UtakataDomainException {
  const YamlParseException(String path)
      : super('Failed to parse YAML: $path');
}
