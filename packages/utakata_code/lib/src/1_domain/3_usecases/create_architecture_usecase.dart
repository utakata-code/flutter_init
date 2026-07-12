import 'package:path/path.dart' as p;
import '../messages/cli_messages.dart';
import '../services/case_converter.dart';

/// プロジェクトのローカルにアーキテクチャ定義のボイラープレートを作成するユースケース
class CreateArchitectureUsecase {
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;
  final bool Function(String path) _fileExists;
  final CliMessages _msg;

  const CreateArchitectureUsecase({
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
    required bool Function(String path) fileExists,
    required CliMessages msg,
  })  : _writeFile = writeFile,
        _ensureDir = ensureDir,
        _fileExists = fileExists,
        _msg = msg;

  /// ボイラープレートを作成する
  Future<void> execute(String architectureId, String projectDir) async {
    final targetPath = p.join(
      projectDir,
      'AI',
      'architecture',
      'arch_definition.yaml',
    );

    // 既にファイルが存在する場合はエラー
    if (_fileExists(targetPath)) {
      throw Exception(_msg.architectureAlreadyExists(targetPath));
    }

    final displayName = CaseConverter.toPascalCase(architectureId);
    final boilerplate = _generateBoilerplate(architectureId, displayName);

    await _ensureDir(p.dirname(targetPath));
    await _writeFile(targetPath, boilerplate);
  }

  String _generateBoilerplate(String id, String displayName) {
    return '''# アーキテクチャ定義: $displayName
#
# この定義ファイルが utakata feature add / feature init が生成する
# ディレクトリ構造と命名規則を決定します。

id: $id
displayName: "$displayName"
guides_path: "AI/architecture/guides"

layers:
  - name: 1_domain
    dirs:
      - 1_entities
      - 2_repositories
      - 3_usecases

  - name: 2_infrastructure
    dirs:
      - 1_models
      - 2_data_sources
      - 3_repositories

  - name: 3_application
    dirs:
      - 1_states
      - 2_providers

naming_rules:
  - dir_pattern: "1_domain/1_entities"
    file_pattern: "^.+_entity\\\\.dart\$"
    description: "{name}_entity.dart"

  - dir_pattern: "1_domain/2_repositories"
    file_pattern: "^.+_repository\\\\.dart\$"
    description: "{name}_repository.dart"

  - dir_pattern: "1_domain/3_usecases"
    file_pattern: "^.+_usecase\\\\.dart\$"
    description: "{name}_usecase.dart"
''';
  }
}
