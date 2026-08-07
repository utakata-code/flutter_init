import 'dart:convert';
import 'dart:io';

import '../../1_domain/1_entities/imports/import_audit_report.dart';
import '../../1_domain/3_usecases/audit_imports_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata imports — import の健全性を決定論的に監査する(Issue #20)
///
/// アーキテクチャ定義の `import_rules` に基づき、lib/ 配下の全 Dart
/// ファイルの import/export を検証する。内部依存はホワイトリスト、
/// 外部依存はブラックリスト。違反があれば exit 1。
class ImportsCommand extends BaseCommand {
  final AuditImportsUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'imports';

  @override
  String get description => _msg.cmdImportsDesc;

  ImportsCommand(this._usecase, this._msg) {
    argParser
      ..addOption('arch', help: _msg.optArchAuto)
      ..addFlag('json', help: _msg.optJson, negatable: false);
  }

  @override
  Future<int> execute() async {
    final result = await _usecase.execute(
      Directory.current.path,
      explicitArch: argResults!['arch'] as String?,
    );
    final report = result.report;
    final asJson = argResults!['json'] as bool;

    if (asJson) {
      final violations = report?.violations ?? const <ImportViolation>[];
      stdout.writeln(jsonEncode({
        'architecture': result.architectureId,
        'has_rules': result.hasRules,
        if (report != null) 'audited_files': report.auditedFileCount,
        if (report != null) 'excluded_files': report.excludedFileCount,
        'violations': [
          for (final v in violations)
            {
              'file': v.filePath,
              'import': v.importUri,
              'kind': v.kind.name,
              'detail': v.detail,
            },
        ],
      }));
      return violations.isEmpty ? 0 : 1;
    }

    if (report == null) {
      Logger.warn('アーキテクチャ "${result.architectureId}" に import_rules が'
          '定義されていません。監査するには arch_definition.yaml に '
          'import_rules を追加してください。');
      return 0;
    }

    Logger.section('🔎 utakata imports — import 監査 (${result.architectureId})');

    if (report.isClean) {
      Logger.success('import 違反はありません'
          '(監査 ${report.auditedFileCount} ファイル、除外 ${report.excludedFileCount})');
      return 0;
    }

    String? currentFile;
    for (final v in report.violations) {
      if (v.filePath != currentFile) {
        currentFile = v.filePath;
        Logger.info('');
        Logger.info('  ${v.filePath}');
      }
      Logger.error("    ✗ import '${v.importUri}' — ${v.detail}");
    }
    Logger.info('');
    Logger.error('${report.violations.length} 件の import 違反'
        '(監査 ${report.auditedFileCount} ファイル、除外 ${report.excludedFileCount})');
    return 1;
  }
}
