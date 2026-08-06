import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/generate_claude_integration_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata claude — Claude Code 統合の管理コマンド群
class ClaudeCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'claude';

  @override
  String get description => _msg.cmdClaudeDesc;

  ClaudeCommand(GenerateClaudeIntegrationUsecase usecase, this._msg) {
    addSubcommand(_ClaudeInitCommand(usecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

/// utakata claude init — 既存プロジェクトに Claude Code 統合を後付け・再生成する
class _ClaudeInitCommand extends BaseCommand {
  final GenerateClaudeIntegrationUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'init';

  @override
  String get description => _msg.cmdClaudeInitDesc;

  _ClaudeInitCommand(this._usecase, this._msg) {
    argParser.addFlag('force', help: _msg.optForceRegenerate, negatable: false);
  }

  @override
  Future<int> execute() async {
    final force = argResults!['force'] as bool;
    final written = await _usecase.execute(
      Directory.current.path,
      skipExisting: !force,
      forceClaudeMd: force,
    );

    if (written.isEmpty) {
      Logger.info('すべて揃っています(生成対象なし)。再生成するには --force を指定してください。');
      return 0;
    }
    for (final path in written) {
      Logger.success('wrote: $path');
    }
    if (!force) {
      Logger.dim('既存ファイルは保護されました。全て再生成するには --force。');
    }
    return 0;
  }
}
