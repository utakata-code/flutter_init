import 'dart:io';

import '../../1_domain/3_usecases/render_summary_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata summary — 案件整理サマリーのマーカー区間を再生成する
class SummaryCommand extends BaseCommand {
  final RenderSummaryUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'summary';
  @override
  String get description => _msg.cmdSummaryDesc;

  SummaryCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    await _usecase.execute(Directory.current.path);
    Logger.success(_msg.summaryRenderDone);
    return 0;
  }
}
