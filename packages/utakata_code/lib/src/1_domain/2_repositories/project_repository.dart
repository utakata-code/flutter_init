/// プロジェクト状態の読み書きを行うリポジトリのインターフェース
///
/// 実装は 2_infrastructure/3_repositories/project_repository_impl.dart に存在する。
/// AI/specs/ や AI/snapshots/ 配下の YAML ファイルを操作する。
abstract interface class ProjectRepository {
  /// feature_request.yaml を読み込んで Map として返す
  ///
  /// [projectDir]: プロジェクトのルートディレクトリパス
  Future<Map<String, dynamic>> readFeatureRequest(String projectDir);

  /// plan_architecture.yaml を書き込む
  ///
  /// [projectDir]: プロジェクトのルートディレクトリパス
  /// [plan]: 書き込む計画データ
  Future<void> writePlanArchitecture(String projectDir, Map<String, dynamic> plan);

  /// plan_architecture.yaml を読み込む
  Future<Map<String, dynamic>?> readPlanArchitecture(String projectDir);

  /// current_structure.yaml を読み込む
  Future<Map<String, dynamic>?> readCurrentStructure(String projectDir);

  /// current_structure.yaml を書き込む
  Future<void> writeCurrentStructure(String projectDir, Map<String, dynamic> structure);

  /// lib/features/ 配下のディレクトリ構造をスキャンして返す
  Future<Map<String, dynamic>> scanFeaturesStructure(String projectDir);
}
