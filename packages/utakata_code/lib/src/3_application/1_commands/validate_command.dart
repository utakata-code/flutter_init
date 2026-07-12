import 'dart:io';

import '../../1_domain/3_usecases/check_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata validate — [非推奨] `utakata check` へのエイリアス
class ValidateCommand extends BaseCommand {
  final CheckUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'validate';

  @override
  String get description => _msg.cmdValidateDesc;

  ValidateCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    Logger.warn(_msg.deprecatedAlias('validate', 'check'));
    Logger.section(_msg.sectionValidate);

    final result = await _usecase.execute(Directory.current.path);

    if (result.isClean) {
      Logger.success(_msg.validateOk);
      return 0;
    }

    if (result.namingViolations.isNotEmpty) {
      Logger.warn('\n${_msg.validateNamingHeader}');
      for (final v in result.namingViolations) {
        Logger.info(_msg.validateNamingViolation(v.filePath, v.expectedPattern));
      }
    }

    if (result.missingPaths.isNotEmpty || result.extraPaths.isNotEmpty) {
      Logger.warn('\n${_msg.validateStructureHeader}');
      for (final d in result.missingPaths) {
        Logger.step(_msg.validateMissingDir(d));
      }
      for (final d in result.extraPaths) {
        Logger.step(_msg.validateExtraDir(d));
      }
    }

    Logger.error('\n${_msg.validateSummary(
      result.namingViolations.length,
      result.missingPaths.length,
      result.extraPaths.length,
    )}');

    return 1;
  }
}
