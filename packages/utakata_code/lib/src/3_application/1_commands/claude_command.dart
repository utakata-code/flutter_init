import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/generate_claude_integration_usecase.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata claude — Claude Code 統合の管理コマンド群
class ClaudeCommand extends Command<int> {
  @override
  String get name => 'claude';

  @override
  String get description =>
      'Claude Code 統合(.claude/・.mcp.json・CLAUDE.md)の生成・補修';

  ClaudeCommand(GenerateClaudeIntegrationUsecase usecase) {
    addSubcommand(_ClaudeInitCommand(usecase));
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

  @override
  String get name => 'init';

  @override
  String get description =>
      '.claude/(スキル・エージェント・settings)+ .mcp.json + CLAUDE.md を生成する。'
      '既定は欠けているファイルのみ補修(既存は保護)。--force で再生成';

  _ClaudeInitCommand(this._usecase) {
    argParser.addFlag('force',
        help: '既存ファイル(CLAUDE.md 含む)も上書きして再生成する', negatable: false);
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
