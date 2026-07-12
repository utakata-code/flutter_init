import 'dart:io';

import '../../1_domain/3_usecases/doctor_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata doctor — 環境・レイアウトの診断と移行
class DoctorCommand extends BaseCommand {
  final DoctorUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'doctor';

  @override
  String get description => _msg.cmdDoctorDesc;

  DoctorCommand(this._usecase, this._msg) {
    argParser.addFlag('migrate', negatable: false, help: '旧レイアウトから新レイアウトへ移行する');
  }

  @override
  Future<int> execute() async {
    final projectDir = Directory.current.path;

    if (argResults!['migrate'] as bool) {
      final dryRunActions = await _usecase.migrate(projectDir, dryRun: true);
      if (dryRunActions.isEmpty) {
        Logger.info(_msg.doctorMigrateNoneFound);
        return 0;
      }

      Logger.section('移行計画(dry-run):');
      for (final action in dryRunActions) {
        Logger.step('${action.automated ? '✓' : '△(手動確認要)'} ${action.description}');
      }

      stdout.write('この内容で移行を実行しますか？ [y/N] ');
      final confirm = stdin.readLineSync();
      if (confirm?.toLowerCase() != 'y') {
        Logger.warn('中断しました');
        return 0;
      }

      final executed = await _usecase.migrate(projectDir, dryRun: false);
      final automatedCount = executed.where((a) => a.automated).length;
      Logger.success(_msg.doctorMigrateDone(automatedCount));
      return 0;
    }

    final issues = await _usecase.diagnose(projectDir);
    if (issues.isEmpty) {
      Logger.success(_msg.doctorOk);
      return 0;
    }
    for (final issue in issues) {
      Logger.warn(_msg.doctorIssueRow(issue));
    }
    return 1;
  }
}
