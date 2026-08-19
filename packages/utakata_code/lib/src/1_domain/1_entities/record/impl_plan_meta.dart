/// feature 実装計画書(`doc/impl/<lane>/PLAN-NNNN_{feature}.md`)の
/// frontmatter 相当(仕様書 §8)。本文(Markdown)は人間/AI の自由記述領域であり、
/// CLI は frontmatter のみを機械管理する。
///
/// v1.7.0 から状態は**2軸**になった:
///   - [status] 実装そのものの進行
///   - [test]   検証の進行
/// 1本の列にすると「実装完了・テスト未着手」と「実装レビュー中」を区別できず、
/// テストが落ちて実装へ戻る動きも表現できないため。
/// ディレクトリ(レーン)はこの2軸から導出する([ImplLane])。
library;

enum ImplPlanStatus { todo, inProgress, review, done, archived }

/// 検証の進行。[notRequired] は「テスト不要」を**明示**するための値で、
/// 「まだ決めていない([todo])」と区別する。
enum ImplTestStatus { notRequired, todo, inProgress, review, done }

enum ImplPlanBasis { clientAgreed, developerJudgment }

final class ImplPlanOrigin {
  final List<String> agreements;
  final List<String> specs;
  final List<String> messages;

  const ImplPlanOrigin({
    this.agreements = const [],
    this.specs = const [],
    this.messages = const [],
  });

  bool get isEmpty => agreements.isEmpty && specs.isEmpty && messages.isEmpty;
}

final class ImplPlanMeta {
  final String id; // PlanId.value
  final String feature;
  final String backlog;
  final ImplPlanStatus status;
  final ImplTestStatus test;
  final DateTime created;
  final ImplPlanOrigin origin;
  final ImplPlanBasis? basis;

  /// `flutter analyze` / `utakata check` などの自動検証が通ったか([test] の内訳)
  final bool staticVerified;

  /// 実機確認が済んだか([test] の内訳)
  final bool onDeviceVerified;

  /// テスト不要とした理由([test] が [ImplTestStatus.notRequired] のとき)
  final String? testSkipReason;

  final DateTime? completedOn;

  const ImplPlanMeta({
    required this.id,
    required this.feature,
    this.backlog = '',
    this.status = ImplPlanStatus.todo,
    this.test = ImplTestStatus.todo,
    required this.created,
    this.origin = const ImplPlanOrigin(),
    this.basis,
    this.staticVerified = false,
    this.onDeviceVerified = false,
    this.testSkipReason,
    this.completedOn,
  });

  /// 実装・検証ともに完了しているか(レーン導出と `list` の表示に使う)。
  bool get isComplete =>
      status == ImplPlanStatus.done &&
      (test == ImplTestStatus.done || test == ImplTestStatus.notRequired);

  ImplPlanMeta copyWith({
    ImplPlanStatus? status,
    ImplTestStatus? test,
    bool? staticVerified,
    bool? onDeviceVerified,
    String? testSkipReason,
    DateTime? completedOn,
  }) =>
      ImplPlanMeta(
        id: id,
        feature: feature,
        backlog: backlog,
        status: status ?? this.status,
        test: test ?? this.test,
        created: created,
        origin: origin,
        basis: basis,
        staticVerified: staticVerified ?? this.staticVerified,
        onDeviceVerified: onDeviceVerified ?? this.onDeviceVerified,
        testSkipReason: testSkipReason ?? this.testSkipReason,
        completedOn: completedOn ?? this.completedOn,
      );

  /// v1.6.x までの `draft` は `todo` として読む(書き戻しは常に `todo`)。
  static ImplPlanStatus statusFromString(String raw) {
    switch (raw) {
      case 'draft': // 旧称
      case 'todo':
        return ImplPlanStatus.todo;
      case 'in_progress':
        return ImplPlanStatus.inProgress;
      case 'review':
        return ImplPlanStatus.review;
      case 'done':
        return ImplPlanStatus.done;
      case 'archived':
        return ImplPlanStatus.archived;
      default:
        throw ArgumentError('Unknown impl plan status: $raw');
    }
  }

  static String statusToString(ImplPlanStatus status) {
    switch (status) {
      case ImplPlanStatus.todo:
        return 'todo';
      case ImplPlanStatus.inProgress:
        return 'in_progress';
      case ImplPlanStatus.review:
        return 'review';
      case ImplPlanStatus.done:
        return 'done';
      case ImplPlanStatus.archived:
        return 'archived';
    }
  }

  static ImplTestStatus testFromString(String raw) {
    switch (raw) {
      case 'not_required':
        return ImplTestStatus.notRequired;
      case 'todo':
        return ImplTestStatus.todo;
      case 'in_progress':
        return ImplTestStatus.inProgress;
      case 'review':
        return ImplTestStatus.review;
      case 'done':
        return ImplTestStatus.done;
      default:
        throw ArgumentError('Unknown impl test status: $raw');
    }
  }

  static String testToString(ImplTestStatus test) {
    switch (test) {
      case ImplTestStatus.notRequired:
        return 'not_required';
      case ImplTestStatus.todo:
        return 'todo';
      case ImplTestStatus.inProgress:
        return 'in_progress';
      case ImplTestStatus.review:
        return 'review';
      case ImplTestStatus.done:
        return 'done';
    }
  }
}
