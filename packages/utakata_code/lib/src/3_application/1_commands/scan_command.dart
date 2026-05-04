import 'dart:io';

import '../../1_domain/3_usecases/scan_structure_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata scan — 現在の lib/features/ 構造をスナップショット
class ScanCommand extends BaseCommand {
  final ScanStructureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'scan';

  @override
  String get description => _msg.cmdScanDesc;

  ScanCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionScan);
    await _usecase.execute(Directory.current.path);
    Logger.success(_msg.scanDone);
    return 0;
  }
}
