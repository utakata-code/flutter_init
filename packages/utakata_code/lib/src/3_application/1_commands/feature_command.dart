import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/1_entities/feature_spec_entity.dart';
import '../../1_domain/3_usecases/add_feature_usecase.dart';
import '../../1_domain/3_usecases/init_features_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'logger.dart';

/// utakata feature — フィーチャー操作コマンド群
class FeatureCommand extends Command<int> {
  final AddFeatureUsecase _addUsecase;
  final InitFeaturesUsecase _initUsecase;
  final CliMessages _msg;

  @override
  String get name => 'feature';

  @override
  String get description => _msg.cmdFeatureDesc;

  FeatureCommand(this._addUsecase, this._initUsecase, this._msg) {
    addSubcommand(_FeatureAddCommand(_addUsecase, _msg));
    addSubcommand(_FeatureInitCommand(_initUsecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

/// utakata feature add
class _FeatureAddCommand extends Command<int> {
  final AddFeatureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'add';

  @override
  String get description => _msg.cmdFeatureAddDesc;

  _FeatureAddCommand(this._usecase, this._msg) {
    argParser
      ..addOption('entity', abbr: 'e', help: _msg.optEntity)
      ..addOption('permission',
          abbr: 'p',
          defaultsTo: 'user',
          allowed: ['admin', 'user', 'shared', 'direct'],
          help: _msg.optPermission)
      ..addOption('arch', defaultsTo: 'clean_architecture', help: _msg.optArch)
      ..addFlag('yes', abbr: 'y', help: _msg.optYes);
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingFeatureName);
      return 1;
    }

    final featureName = _toSnakeCase(argResults!.rest.first);
    final entityName = _toSnakeCase(
      (argResults!['entity'] as String?) ?? featureName,
    );
    final permission = argResults!['permission'] as String;

    Logger.section(_msg.sectionFeatureAdd(featureName));

    final spec = FeatureSpecEntity(
      featureName: featureName,
      entityName: entityName,
      permission: permission,
      architectureId: argResults!['arch'] as String,
    );

    Logger.info(_msg.featureAddPath(spec.relativePath));

    final skipConfirm = argResults!['yes'] as bool;
    if (!skipConfirm) {
      stdout.write(_msg.confirmGenerate(spec.relativePath));
      final confirm = stdin.readLineSync();
      if (confirm?.toLowerCase() != 'y') {
        Logger.warn(_msg.featureAddCancel);
        return 0;
      }
    }

    await _usecase.execute(Directory.current.path, spec);
    Logger.success(_msg.featureAddDone(featureName));
    return 0;
  }

  String _toSnakeCase(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '_');
}

/// utakata feature init
class _FeatureInitCommand extends Command<int> {
  final InitFeaturesUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'init';

  @override
  String get description => _msg.cmdFeatureInitDesc;

  _FeatureInitCommand(this._usecase, this._msg) {
    argParser.addFlag('dry-run', help: _msg.optDryRun);
  }

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;

    Logger.section(_msg.sectionFeatureInit(dryRun));

    final specs = await _usecase.execute(Directory.current.path, dryRun: dryRun);

    if (specs.isEmpty) {
      Logger.warn(_msg.featureInitNone);
      return 0;
    }

    for (final spec in specs) {
      Logger.step(dryRun
          ? _msg.featureDryRunRow(spec.relativePath)
          : '✅ ${spec.relativePath}');
    }

    if (!dryRun) {
      Logger.success(_msg.featureInitDone(specs.length));
    }
    return 0;
  }
}
