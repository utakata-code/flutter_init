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

  StatusCommand(this._usecase, this._projectRepo, this._msg);

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionStatus);

    final result = await _usecase.execute(Directory.current.path);
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
    final diff = result.diff;
    Logger.info('\n${msg.statusArchHeader}');
    if (diff == null) {
      Logger.warn(msg.statusNoPlan);
    } else if (diff.isClean) {
      Logger.success(msg.statusDiffClean);
    } else {
      Logger.warn(msg.diffSummary(diff.missingCount, diff.extraCount));
    }

    // project_status.yaml を更新
    await _projectRepo.writeProjectStatus(
      Directory.current.path,
      result.projectStatus.toYamlMap(),
    );

    return 0;
  }
}
