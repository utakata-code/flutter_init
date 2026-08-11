/// プロジェクト状態(導出可能な生成物)の書き出しを行うリポジトリのインターフェース。
///
/// 実装は 2_infrastructure/3_repositories/project_repository_impl.dart に存在する。
/// 出力先は `doc/preview/`(v1.6.0〜。それ以前は `AI/snapshots/`)。
///
/// ここで書き出すのはすべて**導出可能な生成物**であり、正はコード自体と
/// `doc/specs/plan.yaml` にある。読み戻して判断に使うことはしない(P1)。
abstract interface class ProjectRepository {
  /// `doc/preview/project_status.yaml` を書き込む(機械可読)
  Future<void> writeProjectStatus(String projectDir, Map<String, dynamic> status);

  /// `doc/preview/project_status.md` を書き込む(人間向け)
  Future<void> writeProjectStatusMarkdown(String projectDir, String markdown);
}
