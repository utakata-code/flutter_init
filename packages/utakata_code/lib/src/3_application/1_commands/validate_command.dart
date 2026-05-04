import 'dart:io';

import '../../1_domain/3_usecases/validate_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata validate — 命名規則 + ディレクトリ構造違反を検出する
class ValidateCommand extends BaseCommand {
  final ValidateUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'validate';

  @override
  String get description => _msg.cmdValidateDesc;

  ValidateCommand(this._usecase, this._msg) {
    argParser.addOption(
      'arch',
      defaultsTo: 'clean_architecture',
      help: _msg.optArch,
    );
  }

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionValidate);

    final result = await _usecase.execute(
      Directory.current.path,
      architectureId: argResults!['arch'] as String,
    );

    if (result.isClean) {
      Logger.success(_msg.validateOk);
      return 0;
    }

    // 命名規則違反
    if (result.namingViolations.isNotEmpty) {
      Logger.warn('\n${_msg.validateNamingHeader}');
      for (final v in result.namingViolations) {
        Logger.info(_msg.validateNamingViolation(v.filePath, v.expectedPattern));
      }
    }

    // ディレクトリ構造違反
    if (result.missingDirs.isNotEmpty || result.extraDirs.isNotEmpty) {
      Logger.warn('\n${_msg.validateStructureHeader}');
      for (final d in result.missingDirs) {
        Logger.step(_msg.validateMissingDir(d));
      }
      for (final d in result.extraDirs) {
        Logger.step(_msg.validateExtraDir(d));
      }
    }

    Logger.error('\n${_msg.validateSummary(
      result.namingViolationCount,
      result.missingDirCount,
      result.extraDirCount,
    )}');

    return 1;
  }
}
