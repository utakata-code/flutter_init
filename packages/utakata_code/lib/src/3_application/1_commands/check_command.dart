import 'dart:convert';
import 'dart:io';

import '../../1_domain/1_entities/structure/check_report.dart';
import '../../1_domain/3_usecases/check_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata check — 構造差分 + 命名規則違反を検出する
///
/// 旧 `diff`(構造差分)+ `validate`(命名検証)を統合したコマンド。
class CheckCommand extends BaseCommand {
  final CheckUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'check';

  @override
  String get description => _msg.cmdCheckDesc;

  CheckCommand(this._usecase, this._msg) {
    argParser
      ..addFlag('json', help: _msg.optJson, negatable: false)
      ..addOption('file', help: _msg.optFile);
  }

  @override
  Future<int> execute() async {
    final report = await _usecase.execute(Directory.current.path);
    final targetFile = argResults!['file'] as String?;
    final filtered = targetFile == null ? report : _filterByFile(report, targetFile);

    if (argResults!['json'] as bool) {
      stdout.writeln(jsonEncode(_toJson(filtered)));
      return filtered.isClean ? 0 : 1;
    }

    Logger.section(_msg.sectionCheck);

    if (filtered.missingPaths.isNotEmpty) {
      Logger.info('\n${_msg.diffMissingHeader}');
      for (final path in filtered.missingPaths) {
        Logger.step(path);
      }
    }

    if (filtered.extraPaths.isNotEmpty) {
      Logger.info('\n${_msg.diffExtraHeader}');
      for (final path in filtered.extraPaths) {
        Logger.step(path);
      }
    }

    if (filtered.namingViolations.isNotEmpty) {
      Logger.info('\n${_msg.namingViolationsHeader}');
      for (final violation in filtered.namingViolations) {
        Logger.step('${violation.filePath} (expected: ${violation.expectedPattern})');
      }
    }

    stdout.writeln();
    if (filtered.isClean) {
      Logger.success(_msg.checkClean);
      return 0;
    }

    Logger.warn(_msg.checkSummary(
      filtered.missingPaths.length,
      filtered.extraPaths.length,
      filtered.namingViolations.length,
    ));
    Logger.error(_msg.checkFail);
    return 1;
  }

  CheckReport _filterByFile(CheckReport report, String file) {
    bool matches(String path) =>
        path == file || path.startsWith('$file/') || file.startsWith('$path/');
    return CheckReport(
      missingPaths: report.missingPaths.where(matches).toList(),
      extraPaths: report.extraPaths.where(matches).toList(),
      namingViolations:
          report.namingViolations.where((v) => matches(v.filePath)).toList(),
    );
  }

  Map<String, dynamic> _toJson(CheckReport report) => {
        'clean': report.isClean,
        'missing': report.missingPaths,
        'extra': report.extraPaths,
        'namingViolations': report.namingViolations
            .map((v) => {'file': v.filePath, 'expected': v.expectedPattern})
            .toList(),
      };
}
