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
}

