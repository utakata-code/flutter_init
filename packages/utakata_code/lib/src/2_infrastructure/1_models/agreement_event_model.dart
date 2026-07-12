import '../../1_domain/1_entities/record/agreement.dart';

/// JSONL の1行(Map)⇔ [AgreementEvent] の変換を担う DTO。
abstract final class AgreementEventModel {
  static AgreementEvent fromMap(Map<String, dynamic> map) => AgreementEvent(
        type: AgreementEventType.values.firstWhere((t) => t.name == map['type']),
        id: map['id'] as String,
        recordedAt: DateTime.parse(map['recorded_at'] as String),
        recordedBy: map['recorded_by'] as String,
        title: map['title'] as String?,
        kind: map['kind'] != null ? AgreementEvent.kindFromString(map['kind'] as String) : null,
        amountValue: (map['amount_value'] as num?)?.toDouble(),
        amountCurrency: map['amount_currency'] as String?,
        paymentTerms: map['payment_terms'] as String?,
        items: (map['items'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        sources: (map['sources'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        correctsId: map['corrects'] as String?,
        backlog: map['backlog'] as String?,
        status: map['status'] != null ? AgreementEvent.statusFromString(map['status'] as String) : null,
        statusOn: map['status_on'] != null ? DateTime.parse(map['status_on'] as String) : null,
        reflectedInPlanId: map['reflected_in_plan'] as String?,
        reflectedInSpec: map['reflected_in_spec'] as String?,
      );

  static Map<String, dynamic> toMap(AgreementEvent event) => {
        'type': event.type.name,
        'id': event.id,
        'recorded_at': event.recordedAt.toIso8601String(),
        'recorded_by': event.recordedBy,
        if (event.title != null) 'title': event.title,
        if (event.kind != null) 'kind': AgreementEvent.kindToString(event.kind!),
        if (event.amountValue != null) 'amount_value': event.amountValue,
        if (event.amountCurrency != null) 'amount_currency': event.amountCurrency,
        if (event.paymentTerms != null) 'payment_terms': event.paymentTerms,
        if (event.items.isNotEmpty) 'items': event.items,
        if (event.sources.isNotEmpty) 'sources': event.sources,
        if (event.correctsId != null) 'corrects': event.correctsId,
        if (event.backlog != null) 'backlog': event.backlog,
        if (event.status != null) 'status': AgreementEvent.statusToString(event.status!),
        if (event.statusOn != null) 'status_on': event.statusOn!.toIso8601String(),
        if (event.reflectedInPlanId != null) 'reflected_in_plan': event.reflectedInPlanId,
        if (event.reflectedInSpec != null) 'reflected_in_spec': event.reflectedInSpec,
      };
}
