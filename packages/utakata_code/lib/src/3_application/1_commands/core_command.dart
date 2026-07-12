import 'dart:io';

import '../../1_domain/3_usecases/generate_core_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata core — [非推奨] `utakata apply --scope core` へのエイリアス
class CoreCommand extends BaseCommand {
  final GenerateCoreUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'core';

  @override
  String get description => _msg.cmdCoreDesc;

  CoreCommand(this._usecase, this._msg) {
    argParser.addOption('arch',
        help: _msg.optArch,
        defaultsTo: null);
  }

  @override
  Future<int> execute() async {
    Logger.warn(_msg.deprecatedAlias('core', 'apply --scope core'));
    Logger.section(_msg.sectionCore);

    final archId = argResults!['arch'] as String?;
    final created = await _usecase.execute(Directory.current.path, archId);

    for (final path in created) {
      Logger.step(_msg.coreModuleRow(path));
    }
    Logger.success(_msg.coreDone(created.length));
    return 0;
  }
}
