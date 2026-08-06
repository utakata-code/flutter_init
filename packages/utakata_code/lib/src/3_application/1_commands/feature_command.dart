import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/1_entities/feature_spec_entity.dart';
import '../../1_domain/3_usecases/add_feature_usecase.dart';
import '../../1_domain/3_usecases/architecture_resolver.dart';
import '../../1_domain/3_usecases/apply_feature_template_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import '../../1_domain/services/case_converter.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata feature — フィーチャー操作コマンド群
class FeatureCommand extends Command<int> {
  final AddFeatureUsecase _addUsecase;
  final ApplyFeatureTemplateUsecase _templateUsecase;
  final CliMessages _msg;

  @override
  String get name => 'feature';

  @override
  String get description => _msg.cmdFeatureDesc;

  FeatureCommand(this._addUsecase, this._templateUsecase, this._msg,
      {required ArchitectureResolver archResolver}) {
    addSubcommand(
        _FeatureAddCommand(_addUsecase, _templateUsecase, _msg, archResolver));
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
  final ApplyFeatureTemplateUsecase _templateUsecase;
  final CliMessages _msg;

  @override
  String get name => 'add';

  @override
  String get description => _msg.cmdFeatureAddDesc;

  final ArchitectureResolver _archResolver;

  _FeatureAddCommand(
      this._usecase, this._templateUsecase, this._msg, this._archResolver) {
    argParser
      ..addOption('entity', abbr: 'e', help: _msg.optEntity)
      ..addOption('permission',
          abbr: 'p',
          defaultsTo: 'user',
          allowed: ['admin', 'user', 'shared', 'direct'],
          help: _msg.optPermission)
      ..addOption('arch', help: _msg.optArch)
      ..addOption('template', help: _msg.optFeatureTemplate)
      ..addFlag('yes', abbr: 'y', help: _msg.optYes);
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingFeatureName);
      return 1;
    }

    final featureName = CaseConverter.toSnakeCase(argResults!.rest.first);
    final templateId = argResults!['template'] as String?;
    // --arch 未指定なら utakata.yaml / plan.yaml から解決する(Issue #11)
    final archId = await _archResolver.resolve(Directory.current.path,
        explicit: argResults!['arch'] as String?);

    if (templateId != null) {
      Logger.section(_msg.sectionFeatureAdd(featureName));
      final spec = await _templateUsecase.execute(
        Directory.current.path,
        featureName,
        templateId,
        architectureId: archId,
      );
      Logger.success(_msg.templateApplied(templateId, spec.relativePath));
      return 0;
    }

    final entityName = CaseConverter.toSnakeCase(
      (argResults!['entity'] as String?) ?? featureName,
    );
    final permission = argResults!['permission'] as String;

    Logger.section(_msg.sectionFeatureAdd(featureName));

    final spec = FeatureSpecEntity(
      featureName: featureName,
      entityName: entityName,
      permission: permission,
      architectureId: archId,
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
