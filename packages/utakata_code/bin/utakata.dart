import 'dart:io';

import 'package:utakata/src/1_domain/messages/messages_resolver.dart';
import 'package:utakata/src/1_domain/3_usecases/add_feature_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/add_log_entry_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/adopt_plan_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/apply_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/check_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/generate_guides_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/create_project_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/doctor_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/generate_core_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/init_doc_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/query_log_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/render_log_preview_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/scan_project_status_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/status_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/jsonl_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_edit_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/2_remote/process_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/architecture_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/conversation_log_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/plan_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/project_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/structure_repository_impl.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/template_repository_impl.dart';
import 'package:utakata/src/3_application/1_commands/apply_command.dart';
import 'package:utakata/src/3_application/1_commands/check_command.dart';
import 'package:utakata/src/3_application/1_commands/core_command.dart';
import 'package:utakata/src/3_application/1_commands/create_command.dart';
import 'package:utakata/src/3_application/1_commands/diff_command.dart';
import 'package:utakata/src/3_application/1_commands/doc_command.dart';
import 'package:utakata/src/3_application/1_commands/doctor_command.dart';
import 'package:utakata/src/3_application/1_commands/feature_command.dart';
import 'package:utakata/src/3_application/1_commands/log_command.dart';
import 'package:utakata/src/3_application/1_commands/plan_command.dart';
import 'package:utakata/src/3_application/1_commands/scan_command.dart';
import 'package:utakata/src/3_application/1_commands/status_command.dart';
import 'package:utakata/src/3_application/1_commands/validate_command.dart';
import 'package:utakata/src/3_application/3_presenters/log_preview_presenter.dart';
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
  const yamlEdit = YamlEditDataSource();

  // flutter 実行ファイルのパスは初回使用時に遅延解決する
  // (plan/check/status --brief 等 flutter を使わないコマンドを妨げない)。
  const process = ProcessDataSource();
  const jsonl = JsonlDataSource();

  // リポジトリ実装
  final archRepo = ArchitectureRepositoryImpl(fs, yaml);
  final templateRepo = TemplateRepositoryImpl(fs);
  final projectRepo = ProjectRepositoryImpl(fs, yaml);
  final planRepo = PlanRepositoryImpl(fs, yaml, yamlEdit);
  final structureRepo = StructureRepositoryImpl(fs);
  final logRepo = ConversationLogRepositoryImpl(jsonl);

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

  final generateCoreUsecase = GenerateCoreUsecase(
    archRepo: archRepo,
    ensureDir: fs.ensureDir,
    readFile: fs.readFile,
  );

  final checkUsecase = CheckUsecase(
    planRepo: planRepo,
    archRepo: archRepo,
    structureRepo: structureRepo,
    msg: msg,
  );

  final applyUsecase = ApplyUsecase(
    planRepo: planRepo,
    addFeatureUsecase: addFeatureUsecase,
    generateCoreUsecase: generateCoreUsecase,
  );

  final adoptPlanUsecase = AdoptPlanUsecase(
    planRepo: planRepo,
    structureRepo: structureRepo,
  );

  final scanProjectStatusUsecase = ScanProjectStatusUsecase(
    archRepo: archRepo,
    readFile: fs.readFile,
    fileExists: fs.fileExists,
    dirExists: fs.dirExists,
    scanDartFiles: fs.scanDartFiles,
  );

  final statusUsecase = StatusUsecase(
    checkUsecase: checkUsecase,
    scanStatusUsecase: scanProjectStatusUsecase,
    msg: msg,
    runFlutterAnalyze: process.flutterAnalyze,
    getFlutterVersion: process.flutterVersion,
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

  final initDocUsecase = InitDocUsecase(
    ensureDir: fs.ensureDir,
    writeFile: fs.writeFile,
    fileExists: fs.fileExists,
  );

  final addLogEntryUsecase = AddLogEntryUsecase(repo: logRepo);
  final queryLogUsecase = QueryLogUsecase(repo: logRepo);
  final renderLogPreviewUsecase = RenderLogPreviewUsecase(
    repo: logRepo,
    renderDay: LogPreviewPresenter.renderDay,
    writeFile: fs.writeFile,
  );

  final doctorUsecase = DoctorUsecase(
    planRepo: planRepo,
    fileExists: fs.fileExists,
    dirExists: fs.dirExists,
    readFile: fs.readFile,
    deleteFile: fs.deleteFile,
    deleteDir: fs.deleteDir,
    movePath: fs.movePath,
    listEntries: fs.listEntries,
  );

  // ─── Application 層の組み立て ───
  final runner = UtakataCommandRunner(
    msg: msg,
    createCommand: CreateCommand(createProjectUsecase, msg),
    featureCommand: FeatureCommand(addFeatureUsecase, applyUsecase, msg),
    planCommand: PlanCommand(adoptPlanUsecase, msg),
    scanCommand: ScanCommand(msg),
    diffCommand: DiffCommand(checkUsecase, msg),
    checkCommand: CheckCommand(checkUsecase, msg),
    applyCommand: ApplyCommand(applyUsecase, msg),
    statusCommand: StatusCommand(statusUsecase, projectRepo, msg),
    validateCommand: ValidateCommand(checkUsecase, msg),
    coreCommand: CoreCommand(generateCoreUsecase, msg),
    archCommand: ArchCommand(
      listArchitecturesUsecase,
      showArchitectureUsecase,
      exportArchitectureUsecase,
      createArchitectureUsecase,
      msg,
    ),
    docCommand: DocCommand(initDocUsecase, msg),
    logCommand: LogCommand(addLogEntryUsecase, queryLogUsecase, renderLogPreviewUsecase, msg),
    doctorCommand: DoctorCommand(doctorUsecase, msg),
  );

  // ─── 実行 ───
  final exitCode = await runner.run(arguments) ?? 0;
  exit(exitCode);
}
