import '../../1_domain/1_entities/record/message_record.dart';

/// 送受信原文の1か月分を Markdown プレビューへ変換する。
///
/// 原文は無加工で載せる(要約は `log render` の役割)。
abstract final class MessagePreviewPresenter {
  static String renderMonth(String month, List<MessageRecord> records) {
    final buffer = StringBuffer()
      ..writeln('> ⚠️ 自動生成 — 編集しないでください。'
          '`utakata message render` で再生成されます。')
      ..writeln()
      ..writeln('# $month の送受信原文')
      ..writeln();

    final inbound = records
        .where((r) => r.direction == MessageDirection.inbound)
        .length;
    buffer
      ..writeln('全 ${records.length} 件(受信 $inbound / 送信 '
          '${records.length - inbound})')
      ..writeln();

    for (final record in records) {
      final at = record.at;
      final stamp = '${at.month}/${at.day} '
          '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}'
          '${record.atApprox ? '(概算)' : ''}';
      final label = record.direction == MessageDirection.inbound ? '受信' : '送信';
      final who = record.direction == MessageDirection.inbound
          ? record.from
          : record.to;

      buffer
        ..writeln('### $label $stamp'
            '${who != null ? ' — $who' : ''}'
            '${record.channel != null ? ' [${record.channel}]' : ''}')
        ..writeln('<!-- id: ${record.id}'
            '${record.thread != null ? ' thread: ${record.thread}' : ''} -->')
        ..writeln();

      if (record.subject != null) {
        buffer
          ..writeln('**件名**: ${record.subject}')
          ..writeln();
      }

      buffer
        ..writeln(record.body)
        ..writeln();

      for (final attachment in record.attachments) {
        buffer.writeln('- 添付: `$attachment`');
      }
      final refs = <String>[
        if (record.logRef != null) 'ログ ${record.logRef}',
        if (record.agreementRef != null) '合意 ${record.agreementRef}',
      ];
      if (refs.isNotEmpty) buffer.writeln('_(${refs.join(' / ')})_');
      if (record.attachments.isNotEmpty || refs.isNotEmpty) buffer.writeln();
    }

    return buffer.toString();
  }
}
