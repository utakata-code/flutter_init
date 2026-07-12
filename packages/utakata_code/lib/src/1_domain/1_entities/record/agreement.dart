/// 合意トラッキング(仕様書 §7.2)。
///
/// 追記専用 JSONL + イベント畳み込みで表現する。訂正は過去エントリを
/// 書き換えず、新しいイベント行(`AgreementEventType.correct`)として
/// 追記する(「訂正も履歴ごと残す」実案件慣習をデータ構造で強制する)。
enum AgreementKind { clientAgreement, internalDecision, tentative, correction }

enum AgreementStatus { proposed, agreed, superseded, withdrawn }

enum AgreementEventType { add, statusChange, correct, reflect }

/// `doc/records/agreements.jsonl` の1行(1イベント)。
final class AgreementEvent {
  final AgreementEventType type;
  final String id; // AgrId.value
  final DateTime recordedAt;
  final String recordedBy;

  // add イベント時のフィールド
  final String? title;
  final AgreementKind? kind;
  final double? amountValue;
  final String? amountCurrency;
  final String? paymentTerms;
  final List<String> items;
  final List<String> sources;
  final String? correctsId;
  final String? backlog;

  // statusChange イベント時
  final AgreementStatus? status;
  final DateTime? statusOn;

  // reflect イベント時
  final String? reflectedInPlanId;
  final String? reflectedInSpec;

  const AgreementEvent({
    required this.type,
    required this.id,
    required this.recordedAt,
    required this.recordedBy,
    this.title,
    this.kind,
    this.amountValue,
    this.amountCurrency,
    this.paymentTerms,
    this.items = const [],
    this.sources = const [],
    this.correctsId,
    this.backlog,
    this.status,
    this.statusOn,
    this.reflectedInPlanId,
    this.reflectedInSpec,
  });

  static AgreementKind kindFromString(String raw) {
    switch (raw) {
      case 'client_agreement':
      case 'client':
        return AgreementKind.clientAgreement;
      case 'internal_decision':
      case 'internal':
        return AgreementKind.internalDecision;
      case 'tentative':
        return AgreementKind.tentative;
      case 'correction':
        return AgreementKind.correction;
      default:
        throw ArgumentError('Unknown agreement kind: $raw');
    }
  }

  static String kindToString(AgreementKind kind) {
    switch (kind) {
      case AgreementKind.clientAgreement:
        return 'client_agreement';
      case AgreementKind.internalDecision:
        return 'internal_decision';
      case AgreementKind.tentative:
        return 'tentative';
      case AgreementKind.correction:
        return 'correction';
    }
  }

  static AgreementStatus statusFromString(String raw) =>
      AgreementStatus.values.firstWhere((s) => s.name == raw);

  static String statusToString(AgreementStatus status) => status.name;
}

/// イベント列を畳み込んだ「現在の合意状態」(表示・検索用の派生値)。
final class Agreement {
  final String id;
  final String title;
  final AgreementKind kind;
  final AgreementStatus status;
  final double? amountValue;
  final String? amountCurrency;
  final String? paymentTerms;
  final List<String> items;
  final List<String> sources;
  final String? correctsId;
  final String? backlog;
  final List<String> reflectedInPlanIds;
  final List<String> reflectedInSpecs;
  final DateTime recordedAt;

  const Agreement({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    this.amountValue,
    this.amountCurrency,
    this.paymentTerms,
    this.items = const [],
    this.sources = const [],
    this.correctsId,
    this.backlog,
    this.reflectedInPlanIds = const [],
    this.reflectedInSpecs = const [],
    required this.recordedAt,
  });

  bool get isReflected => reflectedInPlanIds.isNotEmpty || reflectedInSpecs.isNotEmpty;

  /// 同一 ID のイベント列を畳み込んで現在状態を導出する(add が先頭のはず)。
  static Agreement foldFrom(List<AgreementEvent> events) {
    final add = events.firstWhere((e) => e.type == AgreementEventType.add);
    var status = add.status ?? AgreementStatus.proposed;
    final planIds = <String>[];
    final specs = <String>[];

    for (final event in events) {
      switch (event.type) {
        case AgreementEventType.statusChange:
          if (event.status != null) status = event.status!;
          break;
        case AgreementEventType.reflect:
          if (event.reflectedInPlanId != null) planIds.add(event.reflectedInPlanId!);
          if (event.reflectedInSpec != null) specs.add(event.reflectedInSpec!);
          break;
        case AgreementEventType.add:
        case AgreementEventType.correct:
          break;
      }
    }

    return Agreement(
      id: add.id,
      title: add.title ?? '',
      kind: add.kind ?? AgreementKind.tentative,
      status: status,
      amountValue: add.amountValue,
      amountCurrency: add.amountCurrency,
      paymentTerms: add.paymentTerms,
      items: add.items,
      sources: add.sources,
      correctsId: add.correctsId,
      backlog: add.backlog,
      reflectedInPlanIds: planIds,
      reflectedInSpecs: specs,
      recordedAt: add.recordedAt,
    );
  }
}
