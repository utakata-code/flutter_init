import 'dart:io';

import 'package:args/command_runner.dart';

import '../../2_infrastructure/3_repositories/vault_repository_impl.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata vault — 実務ナレッジ Vault の参照
///
/// Vault は「クライアントへの説明に使う知識」(外部サービスのアカウント取得
/// 手順・料金・審査要否など)を蓄積した個人リポジトリ。AI がこれを読んで
/// 説明文を生成し、人間が確認して送信、送った内容は `utakata log add` で
/// 記録する、という流れを想定している。
class VaultCommand extends Command<int> {
  @override
  String get name => 'vault';

  @override
  String get description =>
      '実務ナレッジ Vault(クライアント説明用の外部サービス知識)を参照する';

  VaultCommand(VaultRepositoryImpl vaultRepo) {
    addSubcommand(_VaultListCommand(vaultRepo));
    addSubcommand(_VaultShowCommand(vaultRepo));
    addSubcommand(_VaultGetCommand(vaultRepo));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

void _printNotConfigured() {
  Logger.warn('Vault が設定されていません。');
  Logger.info('');
  Logger.info('`~/.utakata/config.yaml`(全案件共通)に次のように書きます:');
  Logger.info('');
  Logger.info('  vault:');
  Logger.info('    path: "~/path/to/utakata_vault"          # 手元のクローン(優先)');
  Logger.info('    url: "git@github.com:you/your_vault.git" # または git から取得');
  Logger.info('');
  Logger.info('プロジェクトの utakata.yaml に書けばそちらが優先されます。');
}

class _VaultListCommand extends BaseCommand {
  final VaultRepositoryImpl _repo;

  @override
  String get name => 'list';

  @override
  String get description => 'Vault のエントリ一覧を表示する';

  _VaultListCommand(this._repo);

  @override
  Future<int> execute() async {
    final projectDir = Directory.current.path;
    final root = await _repo.resolveRoot(projectDir);
    if (root == null) {
      _printNotConfigured();
      return 1;
    }

    final entries = await _repo.list(projectDir);
    if (entries.isEmpty) {
      Logger.warn('Vault にエントリがありません: $root');
      return 0;
    }

    Logger.section('Vault: $root');
    for (final entry in entries) {
      Logger.info('  ${entry.id}  —  ${entry.title}');
    }
    return 0;
  }
}

class _VaultShowCommand extends BaseCommand {
  final VaultRepositoryImpl _repo;

  @override
  String get name => 'show';

  @override
  String get description =>
      'Vault のエントリ本文を表示する: vault show Google/GCP/Firebase';

  _VaultShowCommand(this._repo);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('エントリを指定してください: utakata vault show <id>'
          '(一覧は `utakata vault list`)');
      return 64;
    }

    final projectDir = Directory.current.path;
    final content = await _repo.read(projectDir, argResults!.rest.first);
    if (content == null) {
      if (await _repo.resolveRoot(projectDir) == null) {
        _printNotConfigured();
      } else {
        Logger.error('エントリ "${argResults!.rest.first}" が見つかりません'
            '(一覧は `utakata vault list`)。');
      }
      return 66;
    }
    stdout.writeln(content);
    return 0;
  }
}

class _VaultGetCommand extends BaseCommand {
  final VaultRepositoryImpl _repo;

  @override
  String get name => 'get';

  @override
  String get description =>
      '設定された url から Vault を取得(再取得)してキャッシュする';

  _VaultGetCommand(this._repo);

  @override
  Future<int> execute() async {
    final path = await _repo.fetch(Directory.current.path);
    if (path == null) {
      Logger.warn('取得対象の url が設定されていません'
          '(`path` で手元のクローンを参照している場合、取得は不要です)。');
      return 0;
    }
    Logger.success('取得しました: $path');
    return 0;
  }
}
