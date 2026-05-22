import '../1_entities/architecture_diff_entity.dart';
import '../2_repositories/project_repository.dart';
import '../messages/cli_messages.dart';

/// アーキテクチャ差分を検証するユースケース
///
/// plan_architecture.yaml と current_structure.yaml を比較し、
/// 計画と実績の差分を ArchitectureDiffEntity として返す。
class DiffArchitectureUsecase {
  final ProjectRepository _projectRepo;
  final CliMessages _msg;

  const DiffArchitectureUsecase({
    required ProjectRepository projectRepo,
    required CliMessages msg,
  })  : _projectRepo = projectRepo,
        _msg = msg;

  /// 差分を計算して返す
  ///
  /// [projectDir]: プロジェクトルートパス
  Future<ArchitectureDiffEntity> execute(String projectDir) async {
    final plan = await _projectRepo.readPlanArchitecture(projectDir);
    final current = await _projectRepo.readCurrentStructure(projectDir);

    if (plan == null) {
      throw Exception(_msg.planNotFound('AI/specs/plan_architecture.yaml'));
    }
    if (current == null) {
      throw Exception(
        _msg.currentStructureNotFound('AI/snapshots/current_structure.yaml'),
      );
    }

    final missingPaths = _collectMissing(plan, current, '');
    final extraPaths = _collectMissing(current, plan, '');

    return ArchitectureDiffEntity(
      missingPaths: missingPaths,
      extraPaths: extraPaths,
    );
  }

  /// expected にあって actual にないパスを収集する（再帰）
  ///
  /// __files__ の扱い:
  ///   - expected（plan）に __files__ があれば、actual（current）と比較する
  ///   - expected（current）に __files__ があっても、plan 側になければスキップ
  ///     （計画になかったファイルは Extra として報告しない）
  List<String> _collectMissing(
    dynamic expected,
    dynamic actual,
    String path,
  ) {
    final missing = <String>[];

    if (expected is Map) {
      final actualMap = actual is Map ? actual : <String, dynamic>{};
      for (final key in expected.keys) {
        if (key == '__files__') {
          // plan に __files__ がある場合はファイル名を比較
          final expectedFiles = expected[key];
          final actualFiles = actualMap[key];
          if (expectedFiles is List) {
            final actualList = actualFiles is List ? actualFiles : <dynamic>[];
            for (final file in expectedFiles) {
              if (!actualList.contains(file)) {
                missing.add(path.isEmpty ? file.toString() : '$path/$file');
              }
            }
          }
          continue;
        }
        final currentPath = path.isEmpty ? '$key' : '$path/$key';
        if (!actualMap.containsKey(key)) {
          missing.add(currentPath);
        } else {
          missing.addAll(_collectMissing(expected[key], actualMap[key], currentPath));
        }
      }
    } else if (expected is List) {
      final actualList = actual is List ? actual : <dynamic>[];
      for (final item in expected) {
        if (!actualList.contains(item)) {
          missing.add('$path/$item');
        }
      }
    }

    return missing;
  }
}
