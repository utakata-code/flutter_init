import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../1_domain/2_repositories/config_repository.dart';
import '../../1_domain/2_repositories/knowledge_repository.dart';
import '../../1_domain/3_usecases/create_architecture_usecase.dart';
import '../../1_domain/3_usecases/export_architecture_usecase.dart';
import '../../1_domain/3_usecases/list_architectures_usecase.dart';
import '../../1_domain/3_usecases/show_architecture_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata arch — アーキテクチャの確認・エクスポート・カスタム作成を行うコマンド群
class ArchCommand extends Command<int> {
  final ListArchitecturesUsecase _listUsecase;
  final ShowArchitectureUsecase _showUsecase;
  final ExportArchitectureUsecase _exportUsecase;
  final CreateArchitectureUsecase _createUsecase;
  final CliMessages _msg;

  @override
  String get name => 'arch';

  @override
  String get description => _msg.cmdArchDesc;

  ArchCommand(
    this._listUsecase,
    this._showUsecase,
    this._exportUsecase,
    this._createUsecase,
    this._msg, {
    ConfigRepository? configRepo,
    KnowledgeRepository? knowledgeRepo,
  }) {
    addSubcommand(_ArchListCommand(_listUsecase, _msg));
    addSubcommand(_ArchShowCommand(_showUsecase, _msg));
    addSubcommand(_ArchExportCommand(_exportUsecase, _msg));
    addSubcommand(_ArchEjectCommand(_createUsecase, _msg));
    addSubcommand(_ArchCreateCommand(_createUsecase, _msg));
    if (configRepo != null && knowledgeRepo != null) {
      addSubcommand(_ArchGetCommand(configRepo, knowledgeRepo));
    }
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

/// utakata arch list — 利用可能なアーキテクチャ定義の一覧を表示する
class _ArchListCommand extends BaseCommand {
  final ListArchitecturesUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'list';

  @override
  String get description => _msg.cmdArchListDesc;

  _ArchListCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    final archs = await _usecase.execute();

    Logger.section(_msg.archListHeader);
    for (final arch in archs) {
      Logger.info('  - ${arch.id}: ${arch.displayName}');
    }
    return 0;
  }
}

/// utakata arch show [id] — 指定したアーキテクチャの定義詳細を表示する
class _ArchShowCommand extends BaseCommand {
  final ShowArchitectureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'show';

  @override
  String get description => _msg.cmdArchShowDesc;

  _ArchShowCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingArchitectureId);
      return 1;
    }

    final archId = argResults!.rest.first;
    final arch = await _usecase.execute(archId);

    Logger.section(_msg.archShowHeader(arch.id, arch.displayName));
    Logger.info('');

    // レイヤー構造のツリー表示
    Logger.info(_msg.archShowLayers);
    final layers = arch.layers;
    for (var i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final isLastLayer = i == layers.length - 1;
      final layerPrefix = isLastLayer ? '└── ' : '├── ';
      final childIndent = isLastLayer ? '    ' : '│   ';

      Logger.info('$layerPrefix${layer.name}');

      for (var j = 0; j < layer.dirs.length; j++) {
        final dir = layer.dirs[j];
        final isLastDir = j == layer.dirs.length - 1;
        final dirPrefix = isLastDir ? '└── ' : '├── ';
        Logger.info('$childIndent$dirPrefix$dir');
      }
    }
    Logger.info('');

    // 命名規則表示
    Logger.info(_msg.archShowNamingRules);
    for (final rule in arch.namingRules) {
      Logger.info('  - ${rule.dirPattern} -> ${rule.description}');
    }

    return 0;
  }
}

/// utakata arch export [id] [path] — 指定したアーキテクチャの定義をYAMLファイルとしてエクスポートする
class _ArchExportCommand extends BaseCommand {
  final ExportArchitectureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'export';

  @override
  String get description => _msg.cmdArchExportDesc;

  _ArchExportCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingArchitectureId);
      return 1;
    }
    if (argResults!.rest.length < 2) {
      Logger.error(_msg.missingOutputPath);
      return 1;
    }

    final archId = argResults!.rest[0];
    final outputPath = argResults!.rest[1];

    await _usecase.execute(archId, outputPath);
    Logger.success(_msg.archExportSuccess(archId, outputPath));
    return 0;
  }
}

/// utakata arch eject [id] — プロジェクトのローカルにアーキテクチャ定義のボイラープレートを書き出す
class _ArchEjectCommand extends BaseCommand {
  final CreateArchitectureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'eject';

  @override
  String get description => _msg.cmdArchCreateDesc;

  _ArchEjectCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingArchitectureId);
      return 1;
    }

    final archId = argResults!.rest.first;
    final projectDir = Directory.current.path;

    await _usecase.execute(archId, projectDir);
    final targetPath = p.join(projectDir, 'AI', 'architecture', 'arch_definition.yaml');
    Logger.success(_msg.archCreateSuccess(archId, targetPath));
    return 0;
  }
}

/// utakata arch create — [非推奨] `utakata arch eject` へのエイリアス
class _ArchCreateCommand extends BaseCommand {
  final CreateArchitectureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'create';

  @override
  String get description => _msg.cmdArchCreateDesc;

  _ArchCreateCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingArchitectureId);
      return 1;
    }

    Logger.warn(_msg.deprecatedAlias('arch create', 'arch eject'));

    final archId = argResults!.rest.first;
    final projectDir = Directory.current.path;

    await _usecase.execute(archId, projectDir);
    final targetPath = p.join(projectDir, 'AI', 'architecture', 'arch_definition.yaml');
    Logger.success(_msg.archCreateSuccess(archId, targetPath));
    return 0;
  }
}

/// utakata arch get — utakata.yaml の knowledge_repo をフェッチし SHA を lock する
class _ArchGetCommand extends BaseCommand {
  final ConfigRepository _configRepo;
  final KnowledgeRepository _knowledgeRepo;

  @override
  String get name => 'get';

  @override
  String get description =>
      'utakata.yaml の project.knowledge_repo をフェッチして utakata.lock に SHA を固定する';

  _ArchGetCommand(this._configRepo, this._knowledgeRepo) {
    argParser.addFlag('update',
        help: 'ref を再解決して lock を更新する', negatable: false);
  }

  @override
  Future<int> execute() async {
    final projectDir = Directory.current.path;
    final config = await _configRepo.read(projectDir);
    final repoRef = config?.knowledgeRepo;
    if (repoRef == null) {
      Logger.warn('utakata.yaml に project.knowledge_repo が指定されていません。'
          'デフォルトの同梱テンプレートを使用中のため、フェッチは不要です。');
      return 0;
    }

    final update = argResults!['update'] as bool;
    final result = await _knowledgeRepo.fetch(projectDir, repoRef, update: update);

    if (!result.refetched) {
      Logger.success('キャッシュ済み (sha: ${result.lock.sha.substring(0, 12)})。'
          '更新するには --update を指定してください。');
      return 0;
    }

    if (result.previousSha != null) {
      Logger.warn('SHA が変わりました: '
          '${result.previousSha!.substring(0, 12)} → ${result.lock.sha.substring(0, 12)}。'
          '内容の差分を確認してからコミットしてください。');
    }
    Logger.success('フェッチ完了: ${repoRef.url} '
        '(ref: ${result.lock.ref.isEmpty ? "default" : result.lock.ref}, '
        'sha: ${result.lock.sha.substring(0, 12)}) → utakata.lock に固定しました。');
    return 0;
  }
}
