import '../1_entities/record/impl_plan_meta.dart';

/// feature 実装計画書(`doc/impl/PLAN-*.md`)の読み書きを行う
/// リポジトリのインターフェース。frontmatter のみ機械管理する(仕様書 §8)。
abstract interface class ImplPlanRepository {
  Future<String> nextId(String projectDir);

  /// [body] は §1〜§8 のテンプレート本文(Markdown)。
  Future<void> create(String projectDir, ImplPlanMeta meta, String body);

  Future<List<ImplPlanMeta>> listAll(String projectDir);

  Future<ImplPlanMeta?> findById(String projectDir, String id);

  Future<void> updateStatus(String projectDir, String id, ImplPlanStatus status,
      {DateTime? completedOn});

  /// `done` 状態のものを `doc/impl/archive/` へ移動する。
  Future<void> archive(String projectDir, String id);
}
