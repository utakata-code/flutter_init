import '../1_entities/template_file_entity.dart';

/// テンプレートファイルを取得するリポジトリのインターフェース
///
/// 実装は 2_infrastructure/3_repositories/template_repository_impl.dart に存在する。
/// lib/src/templates/ 配下の .dart.tmpl / その他ファイルを読み込む。
abstract interface class TemplateRepository {
  /// フィーチャーテンプレートファイルの一覧を取得する
  ///
  /// [architectureId]: 使用するアーキテクチャ識別子
  /// 返されるファイルパスとコンテンツは {{...}} プレースホルダーを含む
  Future<List<TemplateFileEntity>> getFeatureTemplates(String architectureId);

  /// プロジェクトテンプレートファイルの一覧を取得する
  ///
  /// [architectureId]: 使用するアーキテクチャ識別子
  /// .agent/ 配下のスキル・ワークフロー、AI/ 配下のガイド等を含む
  Future<List<TemplateFileEntity>> getProjectTemplates(String architectureId);
}
