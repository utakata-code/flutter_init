import 'package:args/command_runner.dart';

import '../../version.g.dart';
import '../../1_domain/messages/cli_messages.dart';
import '../1_commands/agree_command.dart';
import '../1_commands/apply_command.dart';
import '../1_commands/arch_command.dart';
import '../1_commands/check_command.dart';
import '../1_commands/core_command.dart';
import '../1_commands/create_command.dart';
import '../1_commands/diff_command.dart';
import '../1_commands/doc_command.dart';
import '../1_commands/doctor_command.dart';
import '../1_commands/feature_command.dart';
import '../1_commands/guide_command.dart';
import '../1_commands/impl_command.dart';
import '../1_commands/log_command.dart';
import '../1_commands/plan_command.dart';
import '../1_commands/scan_command.dart';
import '../1_commands/status_command.dart';
import '../1_commands/summary_command.dart';
import '../1_commands/validate_command.dart';

const _version = packageVersion;

// ANSIカラーコード
const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _cyan = '\x1B[96m'; // bright cyan（明るい水色）
const _dim = '\x1B[2m';

/// 起動時のブランドヘッダー（引数なしのとき表示）
String _brandHeader() => '$_bold$_cyan' r'''
██╗   ██╗████████╗ █████╗ ██╗  ██╗ █████╗ ████████╗ █████╗ 
██║   ██║╚══██╔══╝██╔══██╗██║ ██╔╝██╔══██╗╚══██╔══╝██╔══██╗
██║   ██║   ██║   ███████║█████╔╝ ███████║   ██║   ███████║
██║   ██║   ██║   ██╔══██║██╔═██╗ ██╔══██║   ██║   ██╔══██║
╚██████╔╝   ██║   ██║  ██║██║  ██╗██║  ██║   ██║   ██║  ██║
 ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
                                                           
 ██████╗ ██████╗ ██████╗ ███████╗                          
██╔════╝██╔═══██╗██╔══██╗██╔════╝                          
██║     ██║   ██║██║  ██║█████╗                            
██║     ██║   ██║██║  ██║██╔══╝                            
╚██████╗╚██████╔╝██████╔╝███████╗                          
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝                          '''
      '\n$_reset$_dim  spec-driven Flutter development — v$_version$_reset\n';


/// utakata コマンドランナー
///
/// 全コマンドを登録して実行する。
/// DI（依存注入）は bin/utakata.dart で行い、ここではコマンドを受け取るだけ。
class UtakataCommandRunner extends CommandRunner<int> {
  UtakataCommandRunner({
    required CliMessages msg,
    required CreateCommand createCommand,
    required FeatureCommand featureCommand,
    required PlanCommand planCommand,
    required ScanCommand scanCommand,
    required DiffCommand diffCommand,
    required CheckCommand checkCommand,
    required ApplyCommand applyCommand,
    required StatusCommand statusCommand,
    required ValidateCommand validateCommand,
    required CoreCommand coreCommand,
    required ArchCommand archCommand,
    required DocCommand docCommand,
    required LogCommand logCommand,
    required DoctorCommand doctorCommand,
    required AgreeCommand agreeCommand,
    required ImplCommand implCommand,
    required SummaryCommand summaryCommand,
    required GuideCommand guideCommand,
  }) : super(
          'utakata',
          msg.cmdRunnerDesc,
        ) {
    // グローバルオプション
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: msg.versionHelp,
    );

    // コマンド登録
    addCommand(createCommand);
    addCommand(featureCommand);
    addCommand(planCommand);
    addCommand(scanCommand);
    addCommand(diffCommand);
    addCommand(checkCommand);
    addCommand(applyCommand);
    addCommand(statusCommand);
    addCommand(validateCommand);
    addCommand(coreCommand);
    addCommand(archCommand);
    addCommand(docCommand);
    addCommand(logCommand);
    addCommand(doctorCommand);
    addCommand(agreeCommand);
    addCommand(implCommand);
    addCommand(summaryCommand);
    addCommand(guideCommand);
  }

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      final results = parse(args);
      if (results['version'] == true) {
        print('utakata version $_version');
        return 0;
      }
      // 引数なしのとき: ブランドヘッダー + ヘルプを表示
      if (results.command == null) {
        print(_brandHeader());
      }
      return await runCommand(results) ?? 0;
    } on UsageException catch (e) {
      print(e.message);
      print(e.usage);
      return 64; // EX_USAGE
    }
  }
}
