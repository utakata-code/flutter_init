import '../1_entities/record/impl_plan_meta.dart';

/// feature 実装計画書(`doc/impl/<lane>/PLAN-*.md`)の読み書きを行う
/// リポジトリのインターフェース。frontmatter のみ機械管理する(仕様書 §8)。
///
/// v1.7.0 からファイルは状態に応じた**レーン**(サブディレクトリ)に置かれる。
/// 正は frontmatter であり、配置はそこから導出される([ImplLane])。
abstract interface class ImplPlanRepository {
  /// 次の `PLAN-NNNN`。**archive も含む全レーン**の最大連番 + 1
  /// (archive を無視すると、アーカイブ後に ID を再利用してしまう)。
  Future<String> nextId(String projectDir);

  /// [body] は §1〜§8 のテンプレート本文(Markdown)。
  Future<void> create(String projectDir, ImplPlanMeta meta, String body);

  /// 全レーンの計画を返す(archive を含む)。
  Future<List<ImplPlanMeta>> listAll(String projectDir);

  Future<ImplPlanMeta?> findById(String projectDir, String id);

  /// frontmatter を更新し、**続けて正しいレーンへ移動する**。
  /// 移動が起きた場合は移動先の相対パスを返す(起きなければ null)。
  Future<String?> update(String projectDir, ImplPlanMeta meta);

  /// frontmatter とファイル配置の乖離を検出する。
  /// 返り値は「ID → (現在の相対パス, あるべき相対パス)」。
  Future<Map<String, ({String actual, String expected})>> detectMisplaced(
      String projectDir);

  /// [detectMisplaced] の結果に従ってファイルを移動する。移動した ID を返す。
  Future<List<String>> sync(String projectDir, {bool dryRun = false});
}
