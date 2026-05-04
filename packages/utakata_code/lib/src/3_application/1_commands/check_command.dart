import 'dart:io';

import '../../1_domain/3_usecases/check_structure_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata check — アーキテクチャの健全性チェック（CI 用）
class CheckCommand extends BaseCommand {
  final CheckStructureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'check';

  @override
  String get description => _msg.cmdCheckDesc;

  CheckCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionCheck);

    final diff = await _usecase.execute(Directory.current.path);

    if (diff.isClean) {
      Logger.success(_msg.checkOk);
      return 0;
    } else {
      Logger.warn(_msg.diffSummary(diff.missingCount, diff.extraCount));
      for (final path in diff.missingPaths) {
        Logger.step(_msg.checkMissingRow(path));
      }
      Logger.error(_msg.checkFail);
      return 1;
    }
  }
}
