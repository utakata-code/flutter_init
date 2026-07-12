import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/1_entities/record/log_entry.dart';
import '../../1_domain/3_usecases/add_log_entry_usecase.dart';
import '../../1_domain/3_usecases/query_log_usecase.dart';
import '../../1_domain/3_usecases/render_log_preview_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata log — お客様会話ログの構造化記録(人間専用)
class LogCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'log';

  @override
  String get description => _msg.cmdLogDesc;

  LogCommand(
    AddLogEntryUsecase addUsecase,
    QueryLogUsecase queryUsecase,
    RenderLogPreviewUsecase renderUsecase,
    this._msg,
  ) {
    addSubcommand(_LogAddCommand(addUsecase, _msg));
    addSubcommand(_LogShowCommand(queryUsecase, _msg));
    addSubcommand(_LogRenderCommand(renderUsecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

class _LogAddCommand extends BaseCommand {
  final AddLogEntryUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'add';
  @override
  String get description => _msg.cmdLogAddDesc;

  _LogAddCommand(this._usecase, this._msg) {
    argParser
      ..addOption('speaker', abbr: 's', help: 'client|developer|system|third_party')
      ..addOption('at', help: '例: "6/30 17:41"(省略時は現在時刻)')
      ..addOption('name')
      ..addOption('thread')
      ..addMultiOption('tag')
      ..addOption('reply-to')
      ..addFlag('draft', negatable: false);
  }

  @override
  Future<int> execute() async {
    final rest = argResults!.rest;
    String body;
    if (rest.isNotEmpty) {
      body = rest.join(' ');
    } else if (rest.isEmpty && !stdin.hasTerminal) {
      body = await stdin.transform(const SystemEncoding().decoder).join();
    } else {
      Logger.error('本文を指定してください: utakata log add "本文..." もしくは stdin から渡してください');
      return 1;
    }

    final speaker = argResults!['speaker'] as String?;
    if (speaker == null) {
      Logger.error('--speaker を指定してください(client|developer|system|third_party)');
      return 1;
    }

    final entry = await _usecase.execute(
      Directory.current.path,
      body: body,
      speakerRaw: speaker,
      atRaw: argResults!['at'] as String?,
      now: DateTime.now(),
      recordedBy: Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown',
      name: argResults!['name'] as String?,
      thread: argResults!['thread'] as String?,
      tags: argResults!['tag'] as List<String>,
      replyTo: argResults!['reply-to'] as String?,
      isDraft: argResults!['draft'] as bool,
    );

    Logger.success(_msg.logAddDone(entry.id));
    return 0;
  }
}

class _LogShowCommand extends BaseCommand {
  final QueryLogUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'show';
  @override
  String get description => _msg.cmdLogShowDesc;

  _LogShowCommand(this._usecase, this._msg) {
    argParser
      ..addOption('date')
      ..addOption('thread')
      ..addOption('tag');
  }

  @override
  Future<int> execute() async {
    final id = argResults!.rest.isNotEmpty ? argResults!.rest.first : null;
    final dateRaw = argResults!['date'] as String?;
    final entries = await _usecase.execute(
      Directory.current.path,
      date: dateRaw != null ? DateTime.parse(dateRaw) : null,
      thread: argResults!['thread'] as String?,
      tag: argResults!['tag'] as String?,
      id: id,
    );

    if (entries.isEmpty) {
      Logger.warn(_msg.logShowEmpty);
      return 0;
    }

    for (final entry in entries) {
      Logger.info(
          '${entry.id}  ${entry.at}  ${LogEntry.speakerToString(entry.speaker)}  ${entry.name ?? ''}');
      Logger.step(entry.body.split('\n').first);
    }
    return 0;
  }
}

class _LogRenderCommand extends BaseCommand {
  final RenderLogPreviewUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'render';
  @override
  String get description => _msg.cmdLogRenderDesc;

  _LogRenderCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    await _usecase.execute(Directory.current.path);
    Logger.success(_msg.logRenderDone);
    return 0;
  }
}
