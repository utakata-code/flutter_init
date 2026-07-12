import '../1_entities/structure/check_report.dart';
import '../1_entities/project_status_entity.dart';
import '../messages/cli_messages.dart';
import 'check_usecase.dart';
import 'scan_project_status_usecase.dart';

/// プロジェクトステータスを集計するユースケース
class StatusUsecase {
  final CheckUsecase _checkUsecase;
  final ScanProjectStatusUsecase _scanStatusUsecase;
  final CliMessages _msg;

  /// flutter analyze を実行する関数（Infrastructure から注入）
  final Future<String> Function(String projectDir) _runFlutterAnalyze;

  /// flutter --version を実行する関数
  final Future<String> Function() _getFlutterVersion;

  const StatusUsecase({
    required CheckUsecase checkUsecase,
    required ScanProjectStatusUsecase scanStatusUsecase,
    required CliMessages msg,
    required Future<String> Function(String projectDir) runFlutterAnalyze,
    required Future<String> Function() getFlutterVersion,
  })  : _checkUsecase = checkUsecase,
        _scanStatusUsecase = scanStatusUsecase,
        _msg = msg,
        _runFlutterAnalyze = runFlutterAnalyze,
        _getFlutterVersion = getFlutterVersion;

  /// ステータスを収集して返す(flutter analyze・version を含む完全版)
  Future<ProjectStatusResult> execute(String projectDir) async {
    final results = await Future.wait([
      _getFlutterVersion(),
      _runFlutterAnalyze(projectDir),
    ]);

    final flutterVersion = results[0];
    final analyzeOutput = results[1];
    final check = await _tryCheck(projectDir);
    final projectStatus = await _scanStatusUsecase.execute(projectDir);

    return ProjectStatusResult(
      flutterVersion: flutterVersion,
      analyzeOutput: analyzeOutput,
      check: check,
      msg: _msg,
      projectStatus: projectStatus,
    );
  }

  /// `--brief` 用の軽量版。flutter analyze・version は呼び出さない
  /// (SessionStart フック等、低レイテンシが要求される用途向け。仕様書 §11.2)。
  Future<CheckReport?> executeBrief(String projectDir) => _tryCheck(projectDir);

  /// project_status.yaml/md 更新のみを行う(flutter 呼び出しなし)。
  /// `--brief --write-report`(Stop フック)向け。
  Future<ProjectStatusEntity> scanProjectStatusOnly(String projectDir) =>
      _scanStatusUsecase.execute(projectDir);

  Future<CheckReport?> _tryCheck(String projectDir) async {
    try {
      return await _checkUsecase.execute(projectDir);
    } on Exception {
      // plan.yaml がない場合は check なし。
      // Exception のみ捕捉し、プログラミングエラー(Error 系)は伝播させる(P6)。
      return null;
    }
  }
}

/// ステータス結果データクラス
class ProjectStatusResult {
  final String flutterVersion;
  final String analyzeOutput;
  final CheckReport? check;
  final CliMessages msg;
  final ProjectStatusEntity projectStatus;

  const ProjectStatusResult({
    required this.flutterVersion,
    required this.analyzeOutput,
    required this.msg,
    required this.projectStatus,
    this.check,
  });
}
