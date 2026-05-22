import 'dart:io';

import 'package:utakata/src/1_domain/messages/messages_resolver.dart';
import 'package:utakata/src/1_domain/3_usecases/add_feature_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/generate_guides_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/check_structure_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/create_project_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/diff_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/init_features_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/plan_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/scan_structure_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/status_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/2_remote/process_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/architecture_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/project_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/template_repository_impl.dart';
import 'package:utakata/src/3_application/1_commands/check_command.dart';
import 'package:utakata/src/3_application/1_commands/create_command.dart';
import 'package:utakata/src/3_application/1_commands/diff_command.dart';
import 'package:utakata/src/3_application/1_commands/feature_command.dart';
import 'package:utakata/src/3_application/1_commands/plan_command.dart';
import 'package:utakata/src/3_application/1_commands/scan_command.dart';
import 'package:utakata/src/3_application/1_commands/status_command.dart';
import 'package:utakata/src/3_application/1_commands/validate_command.dart';
import 'package:utakata/src/1_domain/3_usecases/validate_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/list_architectures_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/show_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/export_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/create_architecture_usecase.dart';
import 'package:utakata/src/3_application/1_commands/arch_command.dart';
import 'package:utakata/src/3_application/2_runner/command_runner.dart';

/// utakata CLI エントリポイント
///
/// ここで全ての依存を組み立てる（手動 DI）。
/// 依存の流れ: Infrastructure → Domain UseCase → Application Command
Future<void> main(List<String> arguments) async {
  // ─── 言語解決（最初に 1 度だけ行う）───
  final msg = MessagesResolver.resolve();

  // ─── Infrastructure 層の組み立て ───
  const fs = FilesystemDataSource();
  const yaml = YamlDataSource();

  // flutter 実行ファイルのパスを環境変数 / PATH から自动解決
  final ProcessDataSource process;
  try {
    process = await ProcessDataSource.create();
  } catch (e) {
    stderr.writeln('❌ ${msg.flutterNotFound}');
    exit(1);
  }

  // リポジトリ実装
  final archRepo = ArchitectureRepositoryImpl(fs, yaml);
  final templateRepo = TemplateRepositoryImpl(fs);
  final projectRepo = ProjectRepositoryImpl(fs, yaml);

  // ─── Domain UseCase の組み立て ───
  final generateGuidesUsecase = GenerateGuidesUsecase(
    readFile: fs.readFile,
    writeFile: fs.writeFile,
    ensureDir: fs.ensureDir,
    resolvePackageTemplatePath: fs.resolvePackageTemplatePath,
  );

  final addFeatureUsecase = AddFeatureUsecase(
    archRepo: archRepo,
    templateRepo: templateRepo,
    msg: msg,
    writeFile: fs.writeFile,
    ensureDir: fs.ensureDir,
    generateGuidesUsecase: generateGuidesUsecase,
  );

  final createProjectUsecase = CreateProjectUsecase(
    archRepo: archRepo,
    templateRepo: templateRepo,
    msg: msg,
    runFlutterCreate: ({
      required appName,
      required projectName,
      required org,
      required platforms,
      required description,
    }) =>
        process.flutterCreate(
      appName: appName,
      projectName: projectName,
      org: org,
      platforms: platforms,
      description: description,
    ),
    runBuildRunner: ({required appName}) => process.flutterPubRunBuildRunner(appName: appName),
    readFile: fs.readFile,
    writeFile: fs.writeFile,
    ensureDir: fs.ensureDir,
  );

  final planUsecase = PlanArchitectureUsecase(
    projectRepo: projectRepo,
    archRepo: archRepo,
    msg: msg,
  );

  final scanUsecase = ScanStructureUsecase(
    projectRepo: projectRepo,
    msg: msg,
  );

  final diffUsecase = DiffArchitectureUsecase(
    projectRepo: projectRepo,
    msg: msg,
  );

  final checkUsecase = CheckStructureUsecase(
    diffUsecase: diffUsecase,
    msg: msg,
  );

  final initFeaturesUsecase = InitFeaturesUsecase(
    projectRepo: projectRepo,
    addFeatureUsecase: addFeatureUsecase,
    msg: msg,
  );

  final statusUsecase = StatusUsecase(
    scanUsecase: scanUsecase,
    diffUsecase: diffUsecase,
    msg: msg,
    runFlutterAnalyze: process.flutterAnalyze,
    getFlutterVersion: process.flutterVersion,
  );

  final validateUsecase = ValidateUsecase(
    archRepo: archRepo,
    projectRepo: projectRepo,
    msg: msg,
  );

  final listArchitecturesUsecase = ListArchitecturesUsecase(
    archRepo: archRepo,
  );

  final showArchitectureUsecase = ShowArchitectureUsecase(
    archRepo: archRepo,
  );

  final exportArchitectureUsecase = ExportArchitectureUsecase(
    archRepo: archRepo,
    writeFile: fs.writeFile,
    ensureDir: fs.ensureDir,
  );

  final createArchitectureUsecase = CreateArchitectureUsecase(
    writeFile: fs.writeFile,
    ensureDir: fs.ensureDir,
    fileExists: fs.fileExists,
    msg: msg,
  );

  // ─── Application 層の組み立て ───
  final runner = UtakataCommandRunner(
    msg: msg,
    createCommand: CreateCommand(createProjectUsecase, msg),
    featureCommand: FeatureCommand(addFeatureUsecase, initFeaturesUsecase, msg),
    planCommand: PlanCommand(planUsecase, msg),
    scanCommand: ScanCommand(scanUsecase, msg),
    diffCommand: DiffCommand(diffUsecase, msg),
    checkCommand: CheckCommand(checkUsecase, msg),
    statusCommand: StatusCommand(statusUsecase, msg),
    validateCommand: ValidateCommand(validateUsecase, projectRepo, msg),
    archCommand: ArchCommand(
      listArchitecturesUsecase,
      showArchitectureUsecase,
      exportArchitectureUsecase,
      createArchitectureUsecase,
      msg,
    ),
  );

  // ─── 実行 ───
  final exitCode = await runner.run(arguments) ?? 0;
  exit(exitCode);
}
