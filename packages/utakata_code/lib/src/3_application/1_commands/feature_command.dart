import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/1_entities/feature_spec_entity.dart';
import '../../1_domain/3_usecases/add_feature_usecase.dart';
import '../../1_domain/3_usecases/apply_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import '../../1_domain/services/case_converter.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata feature — フィーチャー操作コマンド群
class FeatureCommand extends Command<int> {
  final AddFeatureUsecase _addUsecase;
  final ApplyUsecase _applyUsecase;
  final CliMessages _msg;

  @override
  String get name => 'feature';

  @override
  String get description => _msg.cmdFeatureDesc;

  FeatureCommand(this._addUsecase, this._applyUsecase, this._msg) {
    addSubcommand(_FeatureAddCommand(_addUsecase, _msg));
    addSubcommand(_FeatureInitCommand(_applyUsecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

/// utakata feature add
class _FeatureAddCommand extends BaseCommand {
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
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingFeatureName);
      return 1;
    }

    final featureName = CaseConverter.toSnakeCase(argResults!.rest.first);
    final entityName = CaseConverter.toSnakeCase(
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
}

/// utakata feature init — [非推奨] `utakata apply --scope feature` へのエイリアス
class _FeatureInitCommand extends BaseCommand {
  final ApplyUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'init';

  @override
  String get description => _msg.cmdFeatureInitDesc;

  _FeatureInitCommand(this._usecase, this._msg) {
    argParser.addFlag('dry-run', help: _msg.optDryRun);
  }

  @override
  Future<int> execute() async {
    final dryRun = argResults!['dry-run'] as bool;

    Logger.warn(_msg.deprecatedAlias('feature init', 'apply --scope feature'));
    Logger.section(_msg.sectionFeatureInit(dryRun));

    final result = await _usecase.execute(
      Directory.current.path,
      scope: 'feature',
      dryRun: dryRun,
    );

    if (result.features.isEmpty) {
      Logger.warn(_msg.featureInitNone);
      return 0;
    }

    for (final spec in result.features) {
      Logger.step(dryRun
          ? _msg.featureDryRunRow(spec.relativePath)
          : '✅ ${spec.relativePath}');
    }

    if (!dryRun) {
      Logger.success(_msg.featureInitDone(result.features.length));
    }
    return 0;
  }
}
