import '../1_entities/plan/plan_intent.dart';

/// 意図レベル計画(`doc/specs/plan.yaml`)の読み書きを行うリポジトリのインターフェース。
///
/// 生成された具象ツリー(旧 plan_architecture.yaml)は扱わない(仕様書 §6)。
abstract interface class PlanRepository {
  /// `doc/specs/plan.yaml` を読む。存在しなければ、旧
  /// `AI/specs/feature_request.yaml` を読み取り専用でフォールバック解釈する
  /// (v0.7 後方互換。ファイルへの書き戻しは行わない)。
  /// どちらも存在しない場合は null を返す。
  Future<PlanIntent?> read(String projectDir);

  /// plan.yaml が存在しなければ新規作成し、意図レベルで書き込む。
  Future<void> write(String projectDir, PlanIntent plan);

  /// スキャンで見つかった未計画 feature を、コメント・書式を保持したまま
  /// plan.yaml の `features:` 配列へ外科的に追記する(`plan adopt`)。
  Future<void> adoptFeature(String projectDir, PlanFeatureIntent feature);
}
