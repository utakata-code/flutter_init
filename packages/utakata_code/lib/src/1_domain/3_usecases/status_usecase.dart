import '../1_entities/architecture_diff_entity.dart';
import '../messages/cli_messages.dart';
import 'diff_architecture_usecase.dart';
import 'scan_structure_usecase.dart';

/// プロジェクトステータスを集計するユースケース
class StatusUsecase {
  final ScanStructureUsecase _scanUsecase;
  final DiffArchitectureUsecase _diffUsecase;
  final CliMessages _msg;

  /// flutter analyze を実行する関数（Infrastructure から注入）
  final Future<String> Function(String projectDir) _runFlutterAnalyze;

  /// flutter --version を実行する関数
  final Future<String> Function() _getFlutterVersion;

  const StatusUsecase({
    required ScanStructureUsecase scanUsecase,
    required DiffArchitectureUsecase diffUsecase,
    required CliMessages msg,
    required Future<String> Function(String projectDir) runFlutterAnalyze,
    required Future<String> Function() getFlutterVersion,
  })  : _scanUsecase = scanUsecase,
        _diffUsecase = diffUsecase,
        _msg = msg,
        _runFlutterAnalyze = runFlutterAnalyze,
        _getFlutterVersion = getFlutterVersion;

  /// ステータスを収集して返す
  Future<ProjectStatusResult> execute(String projectDir) async {
    // 並列で取得
    final results = await Future.wait([
      _getFlutterVersion(),
      _runFlutterAnalyze(projectDir),
    ]);

    final flutterVersion = results[0];
    final analyzeOutput = results[1];

    // scan してから diff
    await _scanUsecase.execute(projectDir);
    ArchitectureDiffEntity? diff;
    try {
      diff = await _diffUsecase.execute(projectDir);
    } catch (_) {
      // plan_architecture.yaml がない場合は diff なし
    }

    return ProjectStatusResult(
      flutterVersion: flutterVersion,
      analyzeOutput: analyzeOutput,
      diff: diff,
      msg: _msg,
    );
  }
}

/// ステータス結果データクラス
class ProjectStatusResult {
  final String flutterVersion;
  final String analyzeOutput;
  final ArchitectureDiffEntity? diff;
  final CliMessages msg;

  const ProjectStatusResult({
    required this.flutterVersion,
    required this.analyzeOutput,
    required this.msg,
    this.diff,
  });
}
