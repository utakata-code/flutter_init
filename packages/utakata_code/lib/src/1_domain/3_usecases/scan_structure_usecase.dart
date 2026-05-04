import '../2_repositories/project_repository.dart';
import '../messages/cli_messages.dart';

/// lib/features/ 配下の現在の構造をスキャンするユースケース
///
/// current_structure.yaml に実績構造を出力する。
class ScanStructureUsecase {
  final ProjectRepository _projectRepo;

  const ScanStructureUsecase({
    required ProjectRepository projectRepo,
    // CliMessages は scan では出力が固定のため使用しないが、
    // 将来の拡張に備えて引数として受け取る
    required CliMessages msg,
  }) : _projectRepo = projectRepo;

  /// 構造をスキャンして保存する
  ///
  /// [projectDir]: プロジェクトルートパス
  Future<Map<String, dynamic>> execute(String projectDir) async {
    final structure = await _projectRepo.scanFeaturesStructure(projectDir);
    await _projectRepo.writeCurrentStructure(projectDir, structure);
    return structure;
  }
}
