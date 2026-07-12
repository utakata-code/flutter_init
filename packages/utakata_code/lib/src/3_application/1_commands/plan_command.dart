import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/adopt_plan_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata plan — plan.yaml 関連コマンド群
///
/// v0.7 で意図レベル化(仕様書 §6)に伴い再編。旧来の
/// `plan_architecture.yaml`(具象ツリー)生成は廃止し、`utakata plan`
/// 単体実行は非推奨の案内のみを表示する no-op になる。
/// 新設の `plan adopt` が実質的な後継機能。
class PlanCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'plan';

  @override
  String get description => _msg.cmdPlanDesc;

  PlanCommand(AdoptPlanUsecase adoptUsecase, this._msg) {
    addSubcommand(_PlanAdoptCommand(adoptUsecase, _msg));
  }

  @override
  Future<int> run() async {
    Logger.warn(_msg.deprecatedAlias('plan', 'plan adopt'));
    return 0;
  }
}

/// utakata plan adopt
class _PlanAdoptCommand extends BaseCommand {
  final AdoptPlanUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'adopt';

  @override
  String get description => _msg.cmdPlanAdoptDesc;

  _PlanAdoptCommand(this._usecase, this._msg) {
    argParser.addFlag('yes', abbr: 'y', help: _msg.optYes);
  }

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionPlanAdopt);

    final projectDir = Directory.current.path;
    final candidates = await _usecase.detect(projectDir);

    if (candidates.isEmpty) {
      Logger.info(_msg.adoptNoneFound);
      return 0;
    }

    for (final candidate in candidates) {
      Logger.step(_msg.adoptCandidateRow(candidate.permission, candidate.name));
    }

    final skipConfirm = argResults!['yes'] as bool;
    var adopted = 0;
    for (final candidate in candidates) {
      if (!skipConfirm) {
        stdout.write(_msg.adoptConfirm(candidate.permission, candidate.name));
        final confirm = stdin.readLineSync();
        if (confirm?.toLowerCase() != 'y') continue;
      }
      await _usecase.adopt(projectDir, candidate);
      adopted++;
    }

    Logger.success(_msg.adoptDone(adopted));
    return 0;
  }
}
