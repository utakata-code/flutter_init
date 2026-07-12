import '../../1_domain/1_entities/record/impl_plan_meta.dart';

/// frontmatter(Map)⇔ [ImplPlanMeta] の変換を担う DTO。
abstract final class ImplPlanFrontMatterModel {
  static ImplPlanMeta fromMap(Map<String, dynamic> map) {
    final originMap = map['origin'];
    final origin = originMap is Map
        ? ImplPlanOrigin(
            agreements: (originMap['agreements'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
            specs: (originMap['specs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
            messages:
                (originMap['messages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          )
        : const ImplPlanOrigin();

    final verification = map['verification'];
    final staticVerified = verification is Map && verification['static'] == 'done';
    final onDeviceVerified = verification is Map && verification['on_device'] == 'done';

    return ImplPlanMeta(
      id: map['id'] as String,
      feature: map['feature'] as String,
      backlog: (map['backlog'] as String?) ?? '',
      status: ImplPlanMeta.statusFromString((map['status'] as String?) ?? 'draft'),
      created: DateTime.parse(map['created'] as String),
      origin: origin,
      basis: map['basis'] == 'client_agreed'
          ? ImplPlanBasis.clientAgreed
          : map['basis'] == 'developer_judgment'
              ? ImplPlanBasis.developerJudgment
              : null,
      staticVerified: staticVerified,
      onDeviceVerified: onDeviceVerified,
      completedOn: map['completed_on'] != null ? DateTime.parse(map['completed_on'] as String) : null,
    );
  }

  static Map<String, dynamic> toMap(ImplPlanMeta meta) => {
        'id': meta.id,
        'feature': meta.feature,
        if (meta.backlog.isNotEmpty) 'backlog': meta.backlog,
        'status': ImplPlanMeta.statusToString(meta.status),
        'created': meta.created.toIso8601String().substring(0, 10),
        'origin': {
          'agreements': meta.origin.agreements,
          'specs': meta.origin.specs,
          'messages': meta.origin.messages,
        },
        if (meta.basis != null)
          'basis': meta.basis == ImplPlanBasis.clientAgreed ? 'client_agreed' : 'developer_judgment',
        'verification': {
          'static': meta.staticVerified ? 'done' : 'pending',
          'on_device': meta.onDeviceVerified ? 'done' : 'pending',
        },
        if (meta.completedOn != null)
          'completed_on': meta.completedOn!.toIso8601String().substring(0, 10),
      };
}
