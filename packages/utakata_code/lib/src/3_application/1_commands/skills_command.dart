import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/sync_skills_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata skills — AI エージェント SKILL の管理コマンド群
class SkillsCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'skills';

  @override
  String get description => _msg.cmdSkillsDesc;

  SkillsCommand(SyncSkillsUsecase syncUsecase, this._msg) {
    addSubcommand(_SkillsSyncCommand(syncUsecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

/// utakata skills sync — utakata.yaml の skills リストを .claude/skills/ に反映する
class _SkillsSyncCommand extends BaseCommand {
  final SyncSkillsUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'sync';

  @override
  String get description => _msg.cmdSkillsSyncDesc;

  _SkillsSyncCommand(this._usecase, this._msg) {
    argParser.addFlag('force', help: _msg.optForceOverwrite, negatable: false);
  }

  @override
  Future<int> execute() async {
    final result = await _usecase.execute(
      Directory.current.path,
      force: argResults!['force'] as bool,
    );

    for (final f in result.synced) {
      Logger.success('synced: .claude/skills/$f');
    }
    for (final f in result.skippedUnmanaged) {
      Logger.warn('skip(手動作成のため保護): .claude/skills/$f');
    }
    for (final f in result.skippedModified) {
      Logger.warn('skip(編集済み managed。--force で上書き): .claude/skills/$f');
    }
    for (final id in result.notFound) {
      Logger.warn('SKILL "$id" がアーキテクチャに見つかりません(utakata.yaml の skills を確認)');
    }
    if (result.notFound.isNotEmpty) {
      Logger.info(result.availableIds.isEmpty
          ? '  このアーキテクチャに同梱 SKILL はありません。'
          : '  利用可能な SKILL: ${result.availableIds.join(', ')}');
      Logger.info('  ※ create が生成する汎用スキル(utakata-structure 等)は同期対象外です(既に配置済み)。');
    }
    for (final id in result.removalCandidates) {
      Logger.warn('削除候補(skills リストから外れた managed): .claude/skills/$id/ '
          '(自動削除はしません)');
    }

    if (result.synced.isEmpty &&
        result.skippedUnmanaged.isEmpty &&
        result.skippedModified.isEmpty &&
        result.notFound.isEmpty) {
      Logger.info('同期対象がありません(utakata.yaml の skills: が空です)。');
    }
    return result.notFound.isEmpty ? 0 : 1;
  }
}
