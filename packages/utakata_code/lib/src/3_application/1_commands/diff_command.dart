import 'dart:io';

import '../../1_domain/3_usecases/check_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata diff — `utakata check` へのエイリアス
///
/// `check` へ統合されたが、実案件の実装計画テンプレート文言
/// (「utakata diff ゼロ維持」)との互換のため、他の非推奨コマンドと異なり
/// v1.1 以降も委譲エイリアスとして残す(仕様書 §4)。
class DiffCommand extends BaseCommand {
  final CheckUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'diff';

  @override
  String get description => _msg.cmdDiffDesc;

  DiffCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    Logger.warn(_msg.deprecatedAlias('diff', 'check'));
    Logger.section(_msg.sectionDiff);

    final report = await _usecase.execute(Directory.current.path);

    if (report.missingPaths.isNotEmpty) {
      Logger.info('\n${_msg.diffMissingHeader}');
      for (final path in report.missingPaths) {
        Logger.step(path);
      }
    }

    if (report.extraPaths.isNotEmpty) {
      Logger.info('\n${_msg.diffExtraHeader}');
      for (final path in report.extraPaths) {
        Logger.step(path);
      }
    }

    stdout.writeln();
    final isClean = report.missingPaths.isEmpty && report.extraPaths.isEmpty;
    if (isClean) {
      Logger.success(_msg.diffClean);
    } else {
      Logger.warn(_msg.diffSummary(report.missingPaths.length, report.extraPaths.length));
    }

    return report.missingPaths.isNotEmpty ? 1 : 0;
  }
}
