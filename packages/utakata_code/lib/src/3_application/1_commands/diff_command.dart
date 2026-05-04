import 'dart:io';

import '../../1_domain/3_usecases/diff_architecture_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata diff — 計画と実績の差分を表示する
class DiffCommand extends BaseCommand {
  final DiffArchitectureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'diff';

  @override
  String get description => _msg.cmdDiffDesc;

  DiffCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionDiff);

    final diff = await _usecase.execute(Directory.current.path);

    if (diff.missingPaths.isNotEmpty) {
      Logger.info('\n${_msg.diffMissingHeader}');
      for (final path in diff.missingPaths) {
        Logger.step(path);
      }
    }

    if (diff.extraPaths.isNotEmpty) {
      Logger.info('\n${_msg.diffExtraHeader}');
      for (final path in diff.extraPaths) {
        Logger.step(path);
      }
    }

    stdout.writeln();
    if (diff.isClean) {
      Logger.success(_msg.diffClean);
    } else {
      Logger.warn(_msg.diffSummary(diff.missingCount, diff.extraCount));
    }

    return diff.missingCount > 0 ? 1 : 0;
  }
}
