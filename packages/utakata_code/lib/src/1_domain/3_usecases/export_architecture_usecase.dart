import 'package:path/path.dart' as p;
import '../2_repositories/architecture_repository.dart';

/// アーキテクチャ定義の生 YAML を指定されたパスにエクスポートするユースケース
class ExportArchitectureUsecase {
  final ArchitectureRepository _archRepo;
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;

  const ExportArchitectureUsecase({
    required ArchitectureRepository archRepo,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
  })  : _archRepo = archRepo,
        _writeFile = writeFile,
        _ensureDir = ensureDir;

  /// エクスポートを実行する
  Future<void> execute(String architectureId, String outputPath) async {
    final rawYaml = await _archRepo.getRawDefinition(architectureId);
    
    // 出力先ディレクトリの存在を保証する
    await _ensureDir(p.dirname(outputPath));
    
    // ファイルに書き込む
    await _writeFile(outputPath, rawYaml);
  }
}
