import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/init_doc_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata doc — doc/ 案件ワークスペース操作コマンド群
class DocCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'doc';

  @override
  String get description => _msg.cmdDocDesc;

  DocCommand(InitDocUsecase initUsecase, this._msg) {
    addSubcommand(_DocInitCommand(initUsecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

class _DocInitCommand extends BaseCommand {
  final InitDocUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'init';
  @override
  String get description => _msg.cmdDocInitDesc;

  _DocInitCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    final created = await _usecase.execute(Directory.current.path);
    if (created) {
      Logger.success(_msg.docInitDone);
    } else {
      Logger.warn(_msg.docInitAlreadyExists);
    }
    return 0;
  }
}
