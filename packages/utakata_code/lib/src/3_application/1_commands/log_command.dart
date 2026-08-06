import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/1_entities/record/log_entry.dart';
import '../../1_domain/3_usecases/add_log_entry_usecase.dart';
import '../../1_domain/3_usecases/import_claude_session_usecase.dart';
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
    addSubcommand(_LogImportCommand(_msg));
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
      ..addOption('at', help: _msg.optLogAt)
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

/// utakata log import claude-session — Claude Code セッションの人間駆動取り込み
class _LogImportCommand extends BaseCommand {
  final CliMessages _msg;

  @override
  String get name => 'import';

  @override
  String get description => _msg.cmdLogImportDesc;

  _LogImportCommand(this._msg) {
    argParser
      ..addFlag('list', help: _msg.optImportList, negatable: false)
      ..addOption('session', help: _msg.optImportSession)
      ..addFlag('last', help: _msg.optImportLast, negatable: false)
      ..addFlag('full', help: _msg.optImportFull, negatable: false)
      ..addFlag('yes', abbr: 'y', help: _msg.optSkipConfirm, negatable: false);
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty || argResults!.rest.first != 'claude-session') {
      Logger.error('取り込み元を指定してください: utakata log import claude-session [--list|--last|--session <id>]');
      return 64;
    }

    final projectDir = Directory.current.path;
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final key = ImportClaudeSessionUsecase.projectKeyOf(projectDir);
    final sourceDir = Directory('$home/.claude/projects/$key');
    if (!sourceDir.existsSync()) {
      Logger.error('Claude Code のセッションが見つかりません: ${sourceDir.path}');
      return 66;
    }

    final files = sourceDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jsonl'))
        .toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    if (argResults!['list'] as bool) {
      for (final f in files) {
        final id = f.uri.pathSegments.last.replaceAll('.jsonl', '');
        Logger.info('${f.lastModifiedSync().toIso8601String().substring(0, 16)}  $id');
      }
      if (files.isEmpty) Logger.warn('セッションがありません。');
      return 0;
    }

    File? target;
    final sessionArg = argResults!['session'] as String?;
    if (sessionArg != null) {
      for (final f in files) {
        if (f.uri.pathSegments.last.startsWith(sessionArg)) target = f;
      }
      if (target == null) {
        Logger.error('セッション "$sessionArg" が見つかりません(--list で確認)');
        return 66;
      }
    } else if (argResults!['last'] as bool) {
      target = files.isEmpty ? null : files.last;
      if (target == null) {
        Logger.error('セッションがありません。');
        return 66;
      }
    } else {
      Logger.error('--list / --last / --session <id> のいずれかを指定してください。');
      return 64;
    }

    final sessionId = target.uri.pathSegments.last.replaceAll('.jsonl', '');
    final result = ImportClaudeSessionUsecase.parse(
      target.readAsLinesSync(),
      sessionId: sessionId,
      includeAll: argResults!['full'] as bool,
    );

    if (result.entries.isEmpty) {
      Logger.warn('取り込めるエントリがありません(user/assistant のテキストが空)。');
      return 0;
    }

    // 取り込み前プレビューと確認(実装計画 S6: 必ず確認を挟む)
    final first = result.entries.first;
    final last = result.entries.last;
    Logger.section('取り込みプレビュー — $sessionId');
    Logger.info('  エントリ数: ${result.entries.length}(user: '
        '${result.entries.where((e) => e.role == 'user').length} / assistant: '
        '${result.entries.where((e) => e.role == 'assistant').length})');
    Logger.info('  期間: ${first.ts} 〜 ${last.ts}');
    Logger.info('  冒頭: ${first.text.split('\n').first.substring(0, first.text.split('\n').first.length.clamp(0, 60))}');
    if (result.redactedCount > 0) {
      Logger.warn('  秘密情報らしい記述を ${result.redactedCount} 箇所 [REDACTED] に置換しました。');
    }
    if (result.skippedLines > 0) {
      Logger.dim('  パース不能行 ${result.skippedLines} 件をスキップしました。');
    }

    if (!(argResults!['yes'] as bool)) {
      stdout.write('doc/records/sessions/ に取り込みますか? [y/N]: ');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer != 'y' && answer != 'yes') {
        Logger.info('中止しました。');
        return 0;
      }
    }

    final date = (first.ts.isNotEmpty ? first.ts : DateTime.now().toIso8601String()).substring(0, 10);
    final baseName = '${date}_${sessionId.substring(0, sessionId.length.clamp(0, 8))}';
    final recordPath = '$projectDir/doc/records/sessions/$baseName.jsonl';
    final previewPath = '$projectDir/doc/preview/sessions/$baseName.md';

    File(recordPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(ImportClaudeSessionUsecase.toJsonl(result.entries));
    File(previewPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
          ImportClaudeSessionUsecase.toMarkdown(result.entries, sessionId));

    Logger.success('取り込みました: doc/records/sessions/$baseName.jsonl '
        '(プレビュー: doc/preview/sessions/$baseName.md)');
    return 0;
  }
}
