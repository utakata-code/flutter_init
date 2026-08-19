import '../1_entities/record/impl_plan_meta.dart';

/// 実装計画が置かれる**レーン**(`doc/impl/` 直下のサブディレクトリ)を
/// 2軸の状態から導出する純関数サービス(v1.7.0)。
///
/// ディレクトリと frontmatter の**両方を正にしない**ため、正は frontmatter 側で、
/// ディレクトリは常にここから導出する。人が手で動かした場合は
/// `utakata impl sync` が frontmatter に合わせて再配置する。
///
/// 4状態 × 5状態のディレクトリは破綻するので、「**今どこで止まっているか**」
/// 1つに畳む:
///   1. 実装が終わっていない → 実装側のレーン
///   2. 実装は終わったが検証が残っている → テスト側のレーン
///   3. 両方終わった → done
///
/// 番号プレフィックスは既存の流儀(`1_domain` / `2_infrastructure`)に揃え、
/// ファイラ上でも進行順に並ぶようにしている。
enum ImplLane {
  todo('1_todo'),
  inProgress('2_in_progress'),
  review('3_review'),
  testTodo('4_test_todo'),
  testInProgress('5_test_in_progress'),
  testReview('6_test_review'),
  done('7_done'),
  archive('archive');

  final String dirName;

  const ImplLane(this.dirName);

  /// 表示順(archive は末尾)。
  static List<ImplLane> get ordered => ImplLane.values;

  static ImplLane of(ImplPlanStatus status, ImplTestStatus test) {
    switch (status) {
      case ImplPlanStatus.archived:
        return ImplLane.archive;
      case ImplPlanStatus.todo:
        return ImplLane.todo;
      case ImplPlanStatus.inProgress:
        return ImplLane.inProgress;
      case ImplPlanStatus.review:
        return ImplLane.review;
      case ImplPlanStatus.done:
        switch (test) {
          case ImplTestStatus.todo:
            return ImplLane.testTodo;
          case ImplTestStatus.inProgress:
            return ImplLane.testInProgress;
          case ImplTestStatus.review:
            return ImplLane.testReview;
          case ImplTestStatus.done:
          case ImplTestStatus.notRequired:
            return ImplLane.done;
        }
    }
  }

  static ImplLane ofMeta(ImplPlanMeta meta) => of(meta.status, meta.test);

  /// ディレクトリ名からレーンを引く(不明なら null = レーン外の配置)。
  static ImplLane? fromDirName(String dirName) {
    for (final lane in ImplLane.values) {
      if (lane.dirName == dirName) return lane;
    }
    return null;
  }
}
