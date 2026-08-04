import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/3_usecases/architecture_resolver.dart';
import '../../1_domain/3_usecases/guide_for_file_usecase.dart';
import '../../1_domain/3_usecases/guide_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata guide — 参照型ナレッジ(GUIDE 等)の閲覧・カスタム開始
class GuideCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'guide';
  @override
  String get description => _msg.cmdGuideDesc;

  GuideCommand(GuideUsecase usecase, this._msg,
      {GuideForFileUsecase? guideForFileUsecase,
      required ArchitectureResolver archResolver}) {
    addSubcommand(_GuideListCommand(usecase, _msg, archResolver));
    addSubcommand(_GuideShowCommand(usecase, _msg, archResolver));
    addSubcommand(_GuideEjectCommand(usecase, _msg, archResolver));
    if (guideForFileUsecase != null) {
      addSubcommand(_GuideForCommand(guideForFileUsecase));
    }
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

class _GuideListCommand extends BaseCommand {
  final GuideUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'list';
  @override
  String get description => _msg.cmdGuideListDesc;

  final ArchitectureResolver _archResolver;

  _GuideListCommand(this._usecase, this._msg, this._archResolver) {
    argParser.addOption('arch',
        help: '未指定なら utakata.yaml / plan.yaml から解決する');
  }

  @override
  Future<int> execute() async {
    final archId = await _archResolver.resolve(Directory.current.path,
        explicit: argResults!['arch'] as String?);
    final guides = await _usecase.list(archId);
    if (guides.isEmpty) {
      Logger.warn(_msg.guideListEmpty);
      return 0;
    }
    for (final g in guides) {
      Logger.info('${g.layerPath}  —  ${g.title}');
    }
    return 0;
  }
}

class _GuideShowCommand extends BaseCommand {
  final GuideUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'show';
  @override
  String get description => _msg.cmdGuideShowDesc;

  final ArchitectureResolver _archResolver;

  _GuideShowCommand(this._usecase, this._msg, this._archResolver) {
    argParser.addOption('arch',
        help: '未指定なら utakata.yaml / plan.yaml から解決する');
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingGuideId);
      return 1;
    }
    final archId = await _archResolver.resolve(Directory.current.path,
        explicit: argResults!['arch'] as String?);
    final content = await _usecase.show(archId, argResults!.rest.first);
    stdout.writeln(content);
    return 0;
  }
}

class _GuideEjectCommand extends BaseCommand {
  final GuideUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'eject';
  @override
  String get description => _msg.cmdGuideEjectDesc;

  final ArchitectureResolver _archResolver;

  _GuideEjectCommand(this._usecase, this._msg, this._archResolver) {
    argParser.addOption('arch',
        help: '未指定なら utakata.yaml / plan.yaml から解決する');
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingGuideId);
      return 1;
    }
    final layerPath = argResults!.rest.first;
    final archId = await _archResolver.resolve(Directory.current.path,
        explicit: argResults!['arch'] as String?);
    final path = await _usecase.eject(
      Directory.current.path,
      archId,
      layerPath,
    );
    Logger.success(_msg.guideEjectDone(layerPath, path));
    return 0;
  }
}

/// utakata guide for `<file>` — ファイルパスから該当レイヤーのガイドを解決する
class _GuideForCommand extends BaseCommand {
  final GuideForFileUsecase _usecase;

  @override
  String get name => 'for';

  @override
  String get description =>
      'ファイルパスから該当レイヤーのガイドを決定論的に解決する(lint エラー修正のコンテキスト供給用)';

  _GuideForCommand(this._usecase) {
    argParser.addFlag('json', help: 'JSON で出力する', negatable: false);
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('ファイルパスを指定してください: utakata guide for <file>');
      return 1;
    }
    final result =
        await _usecase.execute(Directory.current.path, argResults!.rest.first);
    if (result == null) {
      Logger.warn('該当するレイヤーガイドが見つかりません(lib/features/ 配下のファイルを指定してください)');
      return 1;
    }
    if (argResults!['json'] as bool) {
      Logger.info(jsonEncode({'layer_path': result.layerPath, 'guide': result.guide}));
    } else {
      Logger.section('Guide: ${result.layerPath}');
      Logger.info(result.guide);
    }
    return 0;
  }
}
