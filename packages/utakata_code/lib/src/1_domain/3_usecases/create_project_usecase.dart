import 'package:path/path.dart' as p;

import '../1_entities/core_module_entity.dart';
import '../1_entities/project_spec_entity.dart';
import '../2_repositories/architecture_repository.dart';
import '../2_repositories/template_repository.dart';
import '../messages/cli_messages.dart';

/// Flutter プロジェクトを作成するユースケース
///
/// 以下の手順で実行される:
/// 1. flutter create コマンドを実行
/// 2. アーキテクチャ定義に基づく依存関係を pubspec.yaml にマージ
/// 3. アーキテクチャ定義に基づく lib/core/ 基盤を生成
/// 4. プロジェクトテンプレート（.agent/, AI/）を展開
class CreateProjectUsecase {
  final ArchitectureRepository _archRepo;
  final TemplateRepository _templateRepo;
  final CliMessages _msg;

  /// flutter create を実行する関数（Infrastructure から注入）
  final Future<bool> Function({
    required String appName,
    required String projectName,
    required String org,
    required String platforms,
    required String description,
  }) _runFlutterCreate;

  /// build_runner を実行する関数（Infrastructure から注入）
  final Future<bool> Function({
    required String appName,
  }) _runBuildRunner;

  /// ファイル操作関数（Infrastructure から注入）
  final Future<String?> Function(String path) _readFile;
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;

  const CreateProjectUsecase({
    required ArchitectureRepository archRepo,
    required TemplateRepository templateRepo,
    required CliMessages msg,
    required Future<bool> Function({
      required String appName,
      required String projectName,
      required String org,
      required String platforms,
      required String description,
    }) runFlutterCreate,
    required Future<bool> Function({
      required String appName,
    }) runBuildRunner,
    required Future<String?> Function(String path) readFile,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
  })  : _archRepo = archRepo,
        _templateRepo = templateRepo,
        _msg = msg,
        _runFlutterCreate = runFlutterCreate,
        _runBuildRunner = runBuildRunner,
        _readFile = readFile,
        _writeFile = writeFile,
        _ensureDir = ensureDir;

  /// プロジェクトを作成する
  Future<void> execute(ProjectSpecEntity spec) async {
    // 1. flutter create を実行
    final success = await _runFlutterCreate(
      appName: spec.appName,
      projectName: spec.projectName,
      org: spec.org,
      platforms: spec.platforms,
      description: spec.description,
    );
    if (!success) {
      throw Exception(_msg.flutterCreateFailed);
    }

    // 2. アーキテクチャ定義を取得
    final arch = await _archRepo.getById(spec.architectureId);

    // 3. pubspec.yaml にアーキテクチャ依存関係を自動追記
    final pubspecPath = p.join(spec.appName, 'pubspec.yaml');
    final pubspecContent = await _readFile(pubspecPath);
    if (pubspecContent != null) {
      final updatedContent = _mergeDependencies(
        pubspecContent,
        arch.dependencies,
        arch.devDependencies,
      );
      await _writeFile(pubspecPath, updatedContent);
    }

    // 4. プロジェクトテンプレートを展開（.agent/, AI/ 等）
    final templates = await _templateRepo.getProjectTemplates(spec.architectureId);
    final variables = {'project_name': spec.projectName, 'ProjectName': spec.projectName};

    for (final template in templates) {
      var resolvedPath = template.resolvedPath(variables);
      // .tmpl 拡張子の除去判定:
      // AI/architecture/features/ 配下はプロジェクトローカルのフィーチャーテンプレートなので
      // .tmpl を維持する（utakata feature add 時に再利用するため）。
      // それ以外のテンプレート（スクリプト、YAML等）は .tmpl を除去する。
      final isFeatureTemplate = resolvedPath.contains('AI/architecture/features/') ||
          resolvedPath.contains('AI\\architecture\\features\\');
      if (resolvedPath.endsWith('.tmpl') && !isFeatureTemplate) {
        resolvedPath = resolvedPath.substring(0, resolvedPath.length - 5);
      }
      final targetPath = p.join(spec.appName, resolvedPath);
      await _ensureDir(p.dirname(targetPath));

      var content = template.resolvedContent(variables);
      if (template.relativePath.endsWith('.tmpl') && !isFeatureTemplate) {
        content = _replacePlaceholders(content, arch.coreModules);
      }

      await _writeFile(targetPath, content);
    }

    // 5. build_runner を実行（テンプレートファイル展開後）
    final buildSuccess = await _runBuildRunner(appName: spec.appName);
    if (!buildSuccess) {
      throw Exception(_msg.buildRunnerFailed);
    }
  }

  /// pubspec.yaml に依存関係をマージするヘルパーメソッド
  String _mergeDependencies(
    String pubspecContent,
    Map<String, dynamic> archDeps,
    Map<String, dynamic> archDevDeps,
  ) {
    final lines = pubspecContent.split('\n');
    final newLines = <String>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      newLines.add(line);

      // dependencies: セクションの検出
      if (line.trim() == 'dependencies:') {
        archDeps.forEach((pkg, version) {
          // 既存の dependencies をスキャンして、追記対象が既に存在するか確認する
          final exists = lines.any((l) => l.trim().startsWith('$pkg:'));
          if (!exists) {
            if (version is Map) {
              newLines.add('  $pkg:');
              version.forEach((k, v) {
                newLines.add('    $k: $v');
              });
            } else {
              newLines.add('  $pkg: $version');
            }
          }
        });
      }

      // dev_dependencies: セクションの検出
      if (line.trim() == 'dev_dependencies:') {
        archDevDeps.forEach((pkg, version) {
          final exists = lines.any((l) => l.trim().startsWith('$pkg:'));
          if (!exists) {
            if (version is Map) {
              newLines.add('  $pkg:');
              version.forEach((k, v) {
                newLines.add('    $k: $v');
              });
            } else {
              newLines.add('  $pkg: $version');
            }
          }
        });
      }

      i++;
    }

    // もし dev_dependencies: セクションが pubspec.yaml に無かった場合
    final hasDevDeps = lines.any((l) => l.trim() == 'dev_dependencies:');
    if (!hasDevDeps && archDevDeps.isNotEmpty) {
      newLines.add('');
      newLines.add('dev_dependencies:');
      archDevDeps.forEach((pkg, version) {
        if (version is Map) {
          newLines.add('  $pkg:');
          version.forEach((k, v) {
            newLines.add('    $k: $v');
          });
        } else {
          newLines.add('  $pkg: $version');
        }
      });
    }

    return newLines.join('\n');
  }

  /// コアモジュールの定義に基づき、テンプレート内のプレースホルダーを動的に置換する
  String _replacePlaceholders(String content, List<CoreModuleEntity> coreModules) {
    // 1. {{core_modules_yaml_initial}} の置換
    final yamlLines = coreModules.map((m) => '  ${m.id}: false').join('\n');
    var result = content.replaceAll('{{core_modules_yaml_initial}}', yamlLines);

    // 2. {{core_modules_detection}} の置換
    final detectionLines = coreModules.map((m) {
      final envName = m.id.toUpperCase();
      return '$envName=\$(check_bool "\$PROJECT_ROOT/${m.path}")';
    }).join('\n');
    result = result.replaceAll('{{core_modules_detection}}', detectionLines);

    // 3. {{core_modules_yaml_output}} の置換
    final yamlOutputLines = coreModules.map((m) {
      final envName = m.id.toUpperCase();
      return '  echo "  ${m.id}: \$$envName"';
    }).join('\n');
    result = result.replaceAll('{{core_modules_yaml_output}}', yamlOutputLines);

    // 4. {{core_modules_md_output}} の置換
    final mdOutputLines = coreModules.map((m) {
      final envName = m.id.toUpperCase();
      return '  echo "| ${m.displayName} | \$(bool_to_icon \$$envName) |"';
    }).join('\n');
    result = result.replaceAll('{{core_modules_md_output}}', mdOutputLines);

    return result;
  }
}
