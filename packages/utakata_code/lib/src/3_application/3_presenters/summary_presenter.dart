import '../../1_domain/1_entities/record/agreement.dart';

/// 案件整理サマリーのマーカー区間(合意ログ・金額集計)の Markdown を生成する。
abstract final class SummaryPresenter {
  static String renderAgreements(List<Agreement> agreements) {
    if (agreements.isEmpty) {
      return '_(まだ合意が記録されていません。`utakata agree add` で記録してください)_';
    }

    final buffer = StringBuffer();
    double total = 0;
    String? currency;

    for (final a in agreements) {
      final dateStr = '${a.recordedAt.year}-${a.recordedAt.month.toString().padLeft(2, '0')}-'
          '${a.recordedAt.day.toString().padLeft(2, '0')}';
      buffer.writeln('### $dateStr：${a.title}');
      for (final item in a.items) {
        buffer.writeln('- $item');
      }
      final kindLabel = switch (a.kind) {
        AgreementKind.clientAgreement => '合意済み',
        AgreementKind.internalDecision => '内部決定(クライアント合意不要)',
        AgreementKind.tentative => '仮方針',
        AgreementKind.correction => '訂正',
      };
      buffer.writeln('- ステータス: $kindLabel / ${a.status.name}');
      if (a.amountValue != null) {
        buffer.writeln('- 金額: ${a.amountValue} ${a.amountCurrency ?? ''}');
        if (a.kind == AgreementKind.clientAgreement && a.status == AgreementStatus.agreed) {
          total += a.amountValue!;
          currency = a.amountCurrency;
        }
      }
      if (a.sources.isNotEmpty) {
        buffer.writeln('- 参照: ${a.sources.join(', ')}');
      }
      buffer.writeln();
    }

    if (total > 0) {
      buffer.writeln('---');
      buffer.writeln('**開発費合計(合意済み分)**: $total ${currency ?? ''}');
    }

    return buffer.toString().trimRight();
  }
}
