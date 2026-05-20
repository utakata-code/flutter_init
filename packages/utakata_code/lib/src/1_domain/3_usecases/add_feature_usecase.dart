import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/feature_spec_entity.dart';
import '../../1_domain/2_repositories/architecture_repository.dart';
import '../../1_domain/2_repositories/template_repository.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'generate_guides_usecase.dart';

/// フィーチャーを追加するユースケース
class AddFeatureUsecase {
  final ArchitectureRepository _archRepo;
  final TemplateRepository _templateRepo;
  final CliMessages _msg;

  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;

  final GenerateGuidesUsecase _generateGuidesUsecase;

  const AddFeatureUsecase({
    required ArchitectureRepository archRepo,
    required TemplateRepository templateRepo,
    required CliMessages msg,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
    required GenerateGuidesUsecase generateGuidesUsecase,
  })  : _archRepo = archRepo,
        _templateRepo = templateRepo,
        _msg = msg,
        _writeFile = writeFile,
        _ensureDir = ensureDir,
        _generateGuidesUsecase = generateGuidesUsecase;

  /// フィーチャーを生成する
  Future<void> execute(String projectDir, FeatureSpecEntity spec) async {
    final arch = await _archRepo.getById(spec.architectureId);
    final basePath = p.join(projectDir, spec.relativePath);

    // アーキテクチャ定義に基づいてディレクトリを生成
    for (final layer in arch.layers) {
      for (final dir in layer.dirs) {
        final dirPath = p.join(basePath, layer.name, dir);
        try {
          await _ensureDir(dirPath);
        } catch (e) {
          throw Exception(_msg.layerDirCreateFailed(dirPath));
        }
      }
    }

    // テンプレートファイルを展開
    final templates = await _templateRepo.getFeatureTemplates(spec.architectureId);
    final variables = _buildVariables(spec);

    for (final template in templates) {
      final resolvedPath = template.resolvedPath(variables);
      // 動的生成対象の GUIDE.md であれば、静的なコピー処理をスキップする
      if (p.basename(resolvedPath) == 'GUIDE.md') {
        continue;
      }

      final targetPath = p.join(basePath, resolvedPath);
      try {
        await _writeFile(targetPath, template.resolvedContent(variables));
      } catch (e) {
        throw Exception(_msg.templateExpandFailed(targetPath));
      }
    }

    // 動的ガイドの生成 (YAML に guides 定義があれば実行する)
    if (arch.guides.isNotEmpty) {
      try {
        await _generateGuidesUsecase.execute(
          projectDir: projectDir,
          featureRelativePath: spec.relativePath,
          archDefinition: arch,
        );
      } catch (e) {
        throw Exception('ガイド生成に失敗しました: $e');
      }
    }
  }

  Map<String, String> _buildVariables(FeatureSpecEntity spec) => {
        'entity_name': spec.entityName,
        'EntityName': _toPascalCase(spec.entityName),
        'entityName': _toCamelCase(spec.entityName),
        'feature_name': spec.featureName,
        'FeatureName': _toPascalCase(spec.featureName),
        'featureName': _toCamelCase(spec.featureName),
        'permission': spec.permission,
      };

  String _toPascalCase(String input) => input
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join();

  String _toCamelCase(String input) {
    final pascal = _toPascalCase(input);
    if (pascal.isEmpty) return pascal;
    return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
  }
}


