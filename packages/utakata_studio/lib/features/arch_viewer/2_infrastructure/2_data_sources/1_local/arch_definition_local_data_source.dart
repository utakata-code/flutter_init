import 'dart:io';
import 'package:path/path.dart' as p;

/// ファイルシステムから arch_definition.yaml を読み込むデータソース
class ArchDefinitionLocalDataSource {
  static const _yamlPath = 'AI/architecture/arch_definition.yaml';

  Future<String> readYaml(String projectRoot) async {
    final file = File(p.join(projectRoot, _yamlPath));
    if (!await file.exists()) {
      throw FileSystemException('arch_definition.yaml not found', file.path);
    }
    return file.readAsString();
  }
}
