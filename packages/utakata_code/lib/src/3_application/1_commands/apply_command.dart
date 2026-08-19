import 'dart:io';

import '../../1_domain/3_usecases/apply_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata apply — plan.yaml から未生成の feature/core を生成する
///
/// 旧 `feature init`(feature 一括生成)+ `core`(Core ディレクトリ生成)を
/// 統合したコマンド。
class ApplyCommand extends BaseCommand {
  final ApplyUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'apply';

  @override
  String get description => _msg.cmdApplyDesc;

  ApplyCommand(this._usecase, this._msg) {
    argParser
      ..addOption('scope',
          defaultsTo: 'all', allowed: ['all', 'feature', 'core'], help: _msg.optScope)
      ..addFlag('dry-run', help: _msg.optDryRun);
  }

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionApply);

    final scope = argResults!['scope'] as String;
    final dryRun = argResults!['dry-run'] as bool;

    final result = await _usecase.execute(
      Directory.current.path,
      scope: scope,
      dryRun: dryRun,
    );

    for (final feature in result.blockedFeatures) {
      Logger.error(_msg.implPlanRequired(feature));
    }

    if (result.features.isEmpty && result.coreModulePaths.isEmpty) {
      if (result.blockedFeatures.isNotEmpty) return 1;
      Logger.warn(_msg.applyNothingToDo);
      return 0;
    }

    for (final spec in result.features) {
      Logger.step(dryRun
          ? _msg.featureDryRunRow(spec.relativePath)
          : _msg.applyFeatureRow(spec.relativePath));
    }
    for (final path in result.createdFiles) {
      Logger.step(
          dryRun ? _msg.featureDryRunRow(path) : _msg.applyFileRow(path));
    }
    for (final path in result.coreModulePaths) {
      Logger.step(_msg.coreModuleRow(path));
    }

    if (!dryRun) {
      Logger.success(_msg.applyDone(result.features.length, result.coreModulePaths.length));
      if (result.createdFiles.isNotEmpty) {
        Logger.success(_msg.applyFilesDone(result.createdFiles.length));
      }
    }
    return result.blockedFeatures.isEmpty ? 0 : 1;
  }
}
