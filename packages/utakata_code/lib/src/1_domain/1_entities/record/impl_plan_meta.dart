/// feature 実装計画書(`doc/impl/PLAN-NNNN_{feature}.md`)の frontmatter 相当
/// (仕様書 §8)。本文(Markdown)は人間/AI の自由記述領域であり、CLI は
/// frontmatter のみを機械管理する。
enum ImplPlanStatus { draft, inProgress, done, archived }

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
  final DateTime created;
  final ImplPlanOrigin origin;
  final ImplPlanBasis? basis;
  final bool staticVerified;
  final bool onDeviceVerified;
  final DateTime? completedOn;

  const ImplPlanMeta({
    required this.id,
    required this.feature,
    this.backlog = '',
    this.status = ImplPlanStatus.draft,
    required this.created,
    this.origin = const ImplPlanOrigin(),
    this.basis,
    this.staticVerified = false,
    this.onDeviceVerified = false,
    this.completedOn,
  });

  ImplPlanMeta copyWith({
    ImplPlanStatus? status,
    bool? staticVerified,
    bool? onDeviceVerified,
    DateTime? completedOn,
  }) =>
      ImplPlanMeta(
        id: id,
        feature: feature,
        backlog: backlog,
        status: status ?? this.status,
        created: created,
        origin: origin,
        basis: basis,
        staticVerified: staticVerified ?? this.staticVerified,
        onDeviceVerified: onDeviceVerified ?? this.onDeviceVerified,
        completedOn: completedOn ?? this.completedOn,
      );

  static ImplPlanStatus statusFromString(String raw) {
    switch (raw) {
      case 'draft':
        return ImplPlanStatus.draft;
      case 'in_progress':
        return ImplPlanStatus.inProgress;
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
      case ImplPlanStatus.draft:
        return 'draft';
      case ImplPlanStatus.inProgress:
        return 'in_progress';
      case ImplPlanStatus.done:
        return 'done';
      case ImplPlanStatus.archived:
        return 'archived';
    }
  }
}
