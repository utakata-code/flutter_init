import 'dart:io';

import '../../1_domain/2_repositories/project_repository.dart';
import '../../1_domain/3_usecases/status_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata status — プロジェクトステータスを表示する
class StatusCommand extends BaseCommand {
  final StatusUsecase _usecase;
  final ProjectRepository _projectRepo;
  final CliMessages _msg;

  @override
  String get name => 'status';

  @override
  String get description => _msg.cmdStatusDesc;

  StatusCommand(this._usecase, this._projectRepo, this._msg) {
    argParser
      ..addFlag('brief', help: _msg.optBrief, negatable: false)
      ..addFlag('write-report', help: _msg.optWriteReport, negatable: false);
  }

  @override
  Future<int> execute() async {
    final brief = argResults!['brief'] as bool;
    final writeReport = argResults!['write-report'] as bool;
    final projectDir = Directory.current.path;

    if (brief) {
      // SessionStart/Stop フック用の軽量パス。flutter analyze / version は呼び出さない。
      final check = await _usecase.executeBrief(projectDir);
      if (check == null) {
        Logger.warn(_msg.statusNoPlan);
      } else if (check.isClean) {
        Logger.success(_msg.statusDiffClean);
      } else {
        Logger.warn(_msg.checkSummary(
          check.missingPaths.length,
          check.extraPaths.length,
          check.namingViolations.length,
        ));
      }
      if (writeReport) {
        final projectStatus = await _usecase.scanProjectStatusOnly(projectDir);
        await _projectRepo.writeProjectStatus(projectDir, projectStatus.toYamlMap());
        await _projectRepo.writeProjectStatusMarkdown(projectDir, projectStatus.toMarkdown());
      }
      return 0;
    }

    Logger.section(_msg.sectionStatus);

    final result = await _usecase.execute(projectDir);
    final msg = result.msg;

    // Flutter バージョン
    Logger.info('\n${msg.statusFlutterVersionHeader}');
    Logger.dim(result.flutterVersion);

    // Lint 結果
    Logger.info('\n${msg.statusLintHeader}');
    if (result.analyzeOutput.contains('No issues found') ||
        result.analyzeOutput.contains(msg.statusLintOk)) {
      Logger.success(msg.statusLintOk);
    } else {
      Logger.dim(result.analyzeOutput);
    }

    // アーキテクチャ差分
    final check = result.check;
    Logger.info('\n${msg.statusArchHeader}');
    if (check == null) {
      Logger.warn(msg.statusNoPlan);
    } else if (check.isClean) {
      Logger.success(msg.statusDiffClean);
    } else {
      Logger.warn(msg.checkSummary(
        check.missingPaths.length,
        check.extraPaths.length,
        check.namingViolations.length,
      ));
    }

    // project_status.yaml + preview/project_status.md を更新
    await _projectRepo.writeProjectStatus(
      projectDir,
      result.projectStatus.toYamlMap(),
    );
    await _projectRepo.writeProjectStatusMarkdown(
      projectDir,
      result.projectStatus.toMarkdown(),
    );

    return 0;
  }
}
