/// CLI メッセージのインターフェース
///
/// 案 A 採用: UseCase・Command がこの I/F を通じてメッセージを取得する。
/// 実装は JaMessages / EnMessages として提供し、bin/utakata.dart で DI 注入する。
///
/// 言語選択: MessagesResolver.resolve() が環境変数を読んで決定する。
abstract interface class CliMessages {
  // ─── コマンド description ───
  String get cmdCreateDesc;
  String get cmdFeatureDesc;
  String get cmdFeatureAddDesc;
  String get cmdFeatureInitDesc;
  String get cmdPlanDesc;
  String get cmdScanDesc;
  String get cmdDiffDesc;
  String get cmdCheckDesc;
  String get cmdStatusDesc;
  String get cmdRunnerDesc;

  // ─── コマンドランナー ───
  String get versionHelp;

  // ─── オプション help 文字列 ───
  String get optOrg;
  String get optPlatforms;
  String get optDescription;
  String get optArch;
  String get optEntity;
  String get optPermission;
  String get optYes;
  String get optDryRun;
  String get optBrief;
  String get optWriteReport;

  // ─── Logger.section ヘッダー ───
  String sectionCreate(String name);
  String get sectionPlan;
  String get sectionScan;
  String get sectionDiff;
  String get sectionCheck;
  String get sectionStatus;
  String sectionFeatureAdd(String name);
  String sectionFeatureInit(bool dryRun);

  // ─── 共通 ───
  String get cancel;

  // ─── エラー入力 ───
  String get missingAppName;
  String get missingFeatureName;
  String confirmGenerate(String path);
  String projectCreated(String name);

  // ─── plan ───
  String get planMissingFeaturesKey;
  String planDone(int count);

  // ─── feature add ───
  String featureAddPath(String path);
  String featureAddDone(String name);
  String get featureAddCancel;

  // ─── feature init ───
  String get featureInitNone;
  String featureInitDone(int count);
  String featureDryRunRow(String path);

  // ─── scan ───
  String get scanDone;

  // ─── diff ───
  String get diffClean;
  String diffSummary(int missing, int extra);
  String get diffMissingHeader;
  String get diffExtraHeader;

  // ─── check ───
  String get checkOk;
  String get checkFail;
  String checkMissingRow(String path);

  // ─── status ───
  String get statusFlutterVersionHeader;
  String get statusLintHeader;
  String get statusLintOk;
  String get statusArchHeader;
  String get statusNoPlan;
  String get statusDiffClean;

  // ─── エラーメッセージ ───
  String featureRequestNotFound(String path);
  String planNotFound(String path);
  String currentStructureNotFound(String path);
  String notFlutterProject(String dir);
  String get flutterNotFound;
  String yamlParseFailed(String path);
  String get flutterCreateFailed;
  String get buildRunnerFailed;

  // ─── add_feature_usecase ───
  String layerDirCreateFailed(String path);
  String templateExpandFailed(String path);

  // ─── validate ───
  String get cmdValidateDesc;
  String get sectionValidate;
  String get validateOk;
  String get validateNamingHeader;
  String get validateStructureHeader;
  String validateNamingViolation(String file, String expected);
  String validateMissingDir(String path);
  String validateExtraDir(String path);
  String validateSummary(int naming, int missing, int extra);

  // ─── arch subcommands ───
  String get cmdArchDesc;
  String get cmdArchListDesc;
  String get cmdArchShowDesc;
  String get cmdArchExportDesc;
  String get cmdArchCreateDesc;
  String get archListHeader;
  String archShowHeader(String id, String name);
  String get archShowLayers;
  String get archShowNamingRules;
  String archExportSuccess(String id, String path);
  String archCreateSuccess(String id, String path);
  String architectureAlreadyExists(String path);
  String get missingArchitectureId;
  String get missingOutputPath;

  // ─── その他エラー ───
  String guideGenerationFailed(String error);
  String templatePathResolveFailed(String path);

  // ─── core ───
  String get cmdCoreDesc;
  String get sectionCore;
  String coreDone(int count);
  String coreModuleRow(String path);

  // ─── check (v0.7: diff+validate 統合) ───
  String get optJson;
  String get optFile;
  String get namingViolationsHeader;
  String get checkClean;
  String checkSummary(int missing, int extra, int naming);
  String deprecatedAlias(String oldCmd, String newCmd);

  // ─── apply (v0.7: feature init + core 統合) ───
  String get cmdApplyDesc;
  String get optScope;
  String get sectionApply;
  String applyFeatureRow(String path);
  String applyFileRow(String path);
  String applyFilesDone(int fileCount);
  String applyDone(int featureCount, int coreCount);
  String get applyNothingToDo;

  // ─── plan adopt (v0.7) ───
  String get cmdPlanAdoptDesc;
  String get sectionPlanAdopt;
  String get adoptNoneFound;
  String adoptCandidateRow(String permission, String name);
  String adoptConfirm(String permission, String name);
  String adoptDone(int count);

  // ─── doc init (v0.8) ───
  String get cmdDocDesc;
  String get cmdDocInitDesc;
  String get docInitDone;
  String get docInitAlreadyExists;

  // ─── log (v0.8) ───
  String get cmdLogDesc;
  String get cmdLogAddDesc;
  String get cmdLogShowDesc;
  String get cmdLogRenderDesc;
  String logAddDone(String id);
  String get logShowEmpty;
  String get logRenderDone;

  // ─── agree (v0.9) ───
  String get cmdAgreeDesc;
  String get cmdAgreeAddDesc;
  String get cmdAgreeListDesc;
  String get cmdAgreeStatusDesc;
  String agreeAddDone(String id);
  String get agreeListEmpty;
  String agreeStatusDone(String id, String status);

  // ─── impl (v0.9) ───
  String get cmdImplDesc;
  String get cmdImplNewDesc;
  String get cmdImplListDesc;
  String get cmdImplDoneDesc;
  String get cmdImplArchiveDesc;
  String implNewDone(String id, String path);
  String get implListEmpty;
  String implDoneDone(String id);
  String implArchiveDone(String id);

  // ─── summary (v0.9) ───
  String get cmdSummaryDesc;
  String get summaryRenderDone;

  // ─── guide (v1.0) ───
  String get cmdGuideDesc;
  String get cmdGuideListDesc;
  String get cmdGuideShowDesc;
  String get cmdGuideEjectDesc;
  String get guideListEmpty;
  String guideEjectDone(String id, String path);
  String get missingGuideId;

  // ─── doctor (v1.0) ───
  String get cmdDoctorDesc;
  String get doctorOk;
  String doctorIssueRow(String message);
  String get doctorMigrateNoneFound;
  String doctorMigrateDone(int count);

  // ─── mcp (v1.1) ───
  String get cmdMcpDesc;
  String get cmdClaudeDesc;
  String get cmdClaudeInitDesc;
  String get cmdSkillsDesc;
  String get cmdSkillsSyncDesc;
  String get cmdVaultDesc;
  String get cmdVaultListDesc;
  String get cmdVaultShowDesc;
  String get cmdVaultGetDesc;
  String get cmdDocShowDesc;
  String get cmdDocListDesc;
  String get cmdPlanExpandDesc;
  String get cmdPlanAddDesc;
  String get cmdPlanRemoveDesc;
  String get cmdGuideForDesc;
  String get cmdArchGetDesc;
  String get cmdAgreeCorrectDesc;
  String get cmdAgreeReflectDesc;
  String get cmdLogImportDesc;

  // ─── 新コマンドのオプション help ───
  String get optForceOverwrite;
  String get optForceRegenerate;
  String get optUpdateRef;
  String get optExpandDryRun;
  String get optExpandFeature;
  String get optJsonOutput;
  String get optArchAuto;
  String get optImportList;
  String get optImportSession;
  String get optImportLast;
  String get optImportFull;
  String get optSkipConfirm;
  String get optMigrate;
  String get optFeatureTemplate;
  String get optLogAt;

  // ─── feature --template (v1.0) ───
  String get missingTemplateId;
  String templateNotFound(String id);
  String templateApplied(String id, String featureName);
}

