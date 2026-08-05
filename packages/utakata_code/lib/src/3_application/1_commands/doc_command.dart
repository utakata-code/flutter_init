import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/init_doc_usecase.dart';
import '../../1_domain/3_usecases/show_doc_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata doc — doc/ 案件ワークスペース操作コマンド群
class DocCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'doc';

  @override
  String get description => _msg.cmdDocDesc;

  DocCommand(InitDocUsecase initUsecase, this._msg,
      {required ShowDocUsecase showUsecase}) {
    addSubcommand(_DocInitCommand(initUsecase, _msg));
    addSubcommand(_DocShowCommand(showUsecase));
    addSubcommand(_DocListCommand());
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

class _DocInitCommand extends BaseCommand {
  final InitDocUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'init';
  @override
  String get description => _msg.cmdDocInitDesc;

  _DocInitCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    final created = await _usecase.execute(Directory.current.path);
    if (created) {
      Logger.success(_msg.docInitDone);
    } else {
      Logger.warn(_msg.docInitAlreadyExists);
    }
    return 0;
  }
}

/// utakata doc show `<topic>` — 同梱ドキュメント(設定ファイルの書き方)を表示する
class _DocShowCommand extends BaseCommand {
  final ShowDocUsecase _usecase;

  @override
  String get name => 'show';

  @override
  String get description =>
      '設定ファイルの書き方を表示する: doc show config|plan(一覧は doc list)';

  _DocShowCommand(this._usecase);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('トピックを指定してください: utakata doc show <topic>');
      _printTopics();
      return 64;
    }

    final topic = argResults!.rest.first;
    final content = await _usecase.execute(topic);
    if (content == null) {
      Logger.error('ドキュメント "$topic" が見つかりません。');
      _printTopics();
      return 66;
    }
    stdout.writeln(content);
    return 0;
  }
}

/// utakata doc list — 読めるドキュメントの一覧
class _DocListCommand extends BaseCommand {
  @override
  String get name => 'list';

  @override
  String get description => '表示できるドキュメントのトピック一覧';

  @override
  Future<int> execute() async {
    _printTopics();
    return 0;
  }
}

void _printTopics() {
  Logger.info('');
  Logger.info('利用可能なトピック:');
  for (final entry in ShowDocUsecase.descriptions.entries) {
    Logger.info('  ${entry.key.padRight(8)} ${entry.value}');
  }
  Logger.info('');
  Logger.info('例: utakata doc show plan');
}
