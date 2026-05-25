import 'dart:io';

import 'package:path/path.dart' as p;

import '../1_entities/validation_result_entity.dart';
import '../2_repositories/architecture_repository.dart';
import '../2_repositories/project_repository.dart';
import '../messages/cli_messages.dart';

/// 命名規則・ディレクトリ構造違反を検出するユースケース
///
/// `utakata validate` コマンドから呼び出される。
/// 以下の 2 種類の違反を検出する:
///   1. 命名規則違反: arch_definition.yaml の naming_rules に基づく
///   2. ディレクトリ構造違反: plan_architecture.yaml と current_structure.yaml の差分
class ValidateUsecase {
  final ArchitectureRepository _archRepo;
  final ProjectRepository _projectRepo;

  // msg は将来の拡張（詳細エラーメッセージ多言語化）のために受け取るが
  // 違反情報は ValidationResultEntity として返すため Command 層で使用する
  // ignore: unused_field
  final CliMessages _msg;

  const ValidateUsecase({
    required ArchitectureRepository archRepo,
    required ProjectRepository projectRepo,
    required CliMessages msg,
  })  : _archRepo = archRepo,
        _projectRepo = projectRepo,
        _msg = msg;

  /// バリデーションを実行する
  ///
  /// [projectDir]: プロジェクトルートパス
  /// [architectureId]: 使用するアーキテクチャ定義の ID
  Future<ValidationResultEntity> execute(
    String projectDir, {
    String architectureId = 'clean_architecture',
  }) async {
    // アーキテクチャ定義を取得（命名規則を含む）
    final arch = await _archRepo.getById(architectureId);

    // 1. 命名規則違反を検出
    final namingViolations = await _detectNamingViolations(
      projectDir,
      arch.namingRules,
    );

    // 2. ディレクトリ構造違反を検出（plan vs current）
    final plan = await _projectRepo.readPlanArchitecture(projectDir);
    
    // ディスクの最新構造をリアルタイムスキャンし、スナップショットを同期更新
    final current = await _projectRepo.scanFeaturesStructure(projectDir);
    await _projectRepo.writeCurrentStructure(projectDir, current);

    final missingDirs = <String>[];
    final extraDirs = <String>[];

    if (plan != null) {
      missingDirs.addAll(_collectMissing(plan, current, ''));
      extraDirs.addAll(_collectMissing(current, plan, ''));
    }

    return ValidationResultEntity(
      namingViolations: namingViolations,
      missingDirs: missingDirs,
      extraDirs: extraDirs,
    );
  }

  // ─── 命名規則違反の検出 ───────────────────────────────────────────────

  Future<List<NamingViolationEntity>> _detectNamingViolations(
    String projectDir,
    List<dynamic> namingRules,
  ) async {
    final violations = <NamingViolationEntity>[];
    final featuresDir = Directory(p.join(projectDir, 'lib', 'features'));

    if (!featuresDir.existsSync()) return violations;

    // lib/features/ 配下の全 .dart ファイルを走査
    // .freezed.dart / .g.dart 等のコード生成ファイルは除外
    final dartFiles = featuresDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.template.dart'))
        .toList();

    for (final file in dartFiles) {
      // features/ 以降の相対パス
      final relPath = p.relative(file.path, from: p.join(projectDir, 'lib'));
      final fileName = p.basename(file.path);
      final dirPath = p.dirname(relPath).replaceAll(r'\', '/');

      // exceptions/ サブディレクトリ配下のファイルは親ルールを適用しない
      if (dirPath.contains('/exceptions')) continue;

      // マッチするルールを探す
      for (final rule in namingRules) {
        if (rule.matches(dirPath)) {
          if (!rule.regex.hasMatch(fileName)) {
            violations.add(NamingViolationEntity(
              filePath: relPath.replaceAll(r'\', '/'),
              expectedPattern: rule.description,
            ));
          }
          break; // 最初にマッチしたルールのみ適用
        }
      }
    }

    return violations;
  }

  // ─── ディレクトリ差分の検出 ───────────────────────────────────────────

  List<String> _collectMissing(
    dynamic expected,
    dynamic actual,
    String path,
  ) {
    final missing = <String>[];
    if (expected is Map) {
      final actualMap = actual is Map ? actual : <String, dynamic>{};
      for (final key in expected.keys) {
        // __files__ はファイルリストであり、ディレクトリではないのでスキップ
        if (key == '__files__') continue;
        final currentPath = path.isEmpty ? '$key' : '$path/$key';
        if (!actualMap.containsKey(key)) {
          missing.add(currentPath);
        } else {
          missing.addAll(_collectMissing(
            expected[key],
            actualMap[key],
            currentPath,
          ));
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
