import 'cli_messages.dart';

/// 英語メッセージ実装
class EnMessages implements CliMessages {
  const EnMessages();

  // ─── command descriptions ───
  @override
  String get cmdCreateDesc => 'Create a new Flutter project';
  @override
  String get cmdFeatureDesc => 'Add or bulk-generate features';
  @override
  String get cmdFeatureAddDesc => 'Add a single feature';
  @override
  String get cmdFeatureInitDesc =>
      'Bulk-generate all features from plan_architecture.yaml';
  @override
  String get cmdPlanDesc =>
      'Generate an architecture plan from feature_request.yaml';
  @override
  String get cmdScanDesc =>
      'Scan the current directory structure and save to YAML';
  @override
  String get cmdDiffDesc =>
      'Show diff between plan_architecture.yaml and current structure';
  @override
  String get cmdCheckDesc =>
      'Check architecture health (exit 1 if diff found)';
  @override
  String get cmdStatusDesc => 'Show overall project status';
  @override
  String get cmdRunnerDesc =>
      'A spec-driven Flutter development CLI tool';

  // ─── command runner ───
  @override
  String get versionHelp => 'Show version';

  // ─── option help ───
  @override
  String get optOrg => 'Package organization name (e.g. com.example)';
  @override
  String get optPlatforms => 'Target platforms (comma-separated)';
  @override
  String get optDescription => 'Project description';
  @override
  String get optArch => 'Architecture to use (e.g. clean_architecture)';
  @override
  String get optEntity => 'Entity name (defaults to feature name)';
  @override
  String get optPermission => 'Permission level';
  @override
  String get optYes => 'Skip confirmation prompt';
  @override
  String get optDryRun => 'Preview without generating files';

  // ─── Logger.section headers ───
  @override
  String sectionCreate(String name) => '🚀 utakata create — $name';
  @override
  String get sectionPlan => '📝 utakata plan — Generating plan file';
  @override
  String get sectionScan => '📸 utakata scan — Generating snapshot';
  @override
  String get sectionDiff => '⚖️ utakata diff — Architecture diff';
  @override
  String get sectionCheck => '🔍 utakata check — Architecture check';
  @override
  String get sectionStatus => '📊 utakata status — Project status';
  @override
  String sectionFeatureAdd(String name) => '✨ utakata feature add — $name';
  @override
  String sectionFeatureInit(bool dryRun) =>
      '🚀 utakata feature init${dryRun ? ' (dry-run)' : ''}';

  // ─── common ───
  @override
  String get cancel => 'Cancelled.';

  // ─── input errors ───
  @override
  String get missingAppName =>
      'Please specify an app name. Example: utakata create my_app';
  @override
  String get missingFeatureName =>
      'Please specify a feature name. Example: utakata feature add memo';
  @override
  String confirmGenerate(String path) => 'Are you sure you want to generate in "$path"? (y/N)';
  @override
  String projectCreated(String name) => '✅ Project "$name" has been generated!';

  // ─── plan ───
  @override
  String get planMissingFeaturesKey =>
      'feature_request.yaml is missing the "features" key.';
  @override
  String planDone(int count) => 'Architecture plan generated ($count features).';

  // ─── feature add ───
  @override
  String featureAddPath(String path) => '  path: $path';
  @override
  String featureAddDone(String name) => 'Feature "$name" has been generated!';
  @override
  String get featureAddCancel => 'Cancelled.';

  // ─── feature init ───
  @override
  String get featureInitNone => 'No features found to generate.';
  @override
  String featureInitDone(int count) => '$count feature(s) have been generated!';
  @override
  String featureDryRunRow(String path) => '[DRY] $path';

  // ─── scan ───
  @override
  String get scanDone => 'Snapshot generated.';

  // ─── diff ───
  @override
  String get diffClean => 'No diff! Plan and current structure match perfectly.';
  @override
  String diffSummary(int missing, int extra) =>
      'Missing: $missing, Extra: $extra';
  @override
  String get diffMissingHeader => 'Missing (planned but not implemented):';
  @override
  String get diffExtraHeader => 'Extra (implemented but not in plan):';

  // ─── check ───
  @override
  String get checkOk => 'Architecture is healthy!';
  @override
  String get checkFail =>
      'Architecture has issues. Run `utakata diff` for details.';
  @override
  String checkMissingRow(String path) => '[Missing] $path';

  // ─── status ───
  @override
  String get statusFlutterVersionHeader => '--- Flutter Version ---';
  @override
  String get statusLintHeader => '--- Lint Analysis ---';
  @override
  String get statusLintOk => 'No issues found.';
  @override
  String get statusArchHeader => '--- Architecture Diff ---';
  @override
  String get statusNoPlan =>
      'plan_architecture.yaml not found. Run `utakata plan` first.';
  @override
  String get statusDiffClean => 'Plan and current structure are in sync!';

  // ─── errors ───
  @override
  String featureRequestNotFound(String path) =>
      '$path not found. Please create the specification file.';
  @override
  String planNotFound(String path) =>
      '$path not found. Run `utakata plan` first.';
  @override
  String currentStructureNotFound(String path) =>
      '$path not found. Run `utakata scan` first.';
  @override
  String notFlutterProject(String dir) =>
      '$dir is not a Flutter project. Run from the project root.';
  @override
  String get flutterNotFound =>
      'flutter command not found. '
      'Set the FLUTTER_PATH environment variable to the full path. '
      'Example: export FLUTTER_PATH=/path/to/flutter/bin/flutter';
  @override
  String yamlParseFailed(String path) => 'Failed to parse YAML: $path';
  @override
  String get flutterCreateFailed => 'flutter create failed.';
  @override
  String get buildRunnerFailed => 'build_runner execution failed.';

  // ─── add_feature_usecase ───
  @override
  String layerDirCreateFailed(String path) =>
      'Failed to create directory: $path';
  @override
  String templateExpandFailed(String path) =>
      'Failed to expand template: $path';

  // ─── validate ───
  @override
  String get cmdValidateDesc =>
      'Detect naming rule and directory structure violations';
  @override
  String get sectionValidate => '🔎 utakata validate — Naming & Structure Check';
  @override
  String get validateOk =>
      'No naming or directory structure violations found!';
  @override
  String get validateNamingHeader => '[Naming Violations]';
  @override
  String get validateStructureHeader => '[Directory Structure Violations]';
  @override
  String validateNamingViolation(String file, String expected) =>
      '  ❌ $file\n     Expected: $expected';
  @override
  String validateMissingDir(String path) => '  Missing: $path';
  @override
  String validateExtraDir(String path) => '  Extra:   $path';
  @override
  String validateSummary(int naming, int missing, int extra) =>
      'Naming: $naming violation(s) / Missing: $missing / Extra: $extra';

  // ─── arch subcommands ───
  @override
  String get cmdArchDesc => 'Inspect, export, and custom-create architectures';
  @override
  String get cmdArchListDesc => 'List all available architecture definitions';
  @override
  String get cmdArchShowDesc => 'Show detail definition, naming rules, and layer structure tree';
  @override
  String get cmdArchExportDesc => 'Export raw YAML file for the specified architecture';
  @override
  String get cmdArchCreateDesc => 'Create a customizable architecture definition boilerplate locally';
  @override
  String get archListHeader => 'Available Architecture Definitions:';
  @override
  String archShowHeader(String id, String name) => '🏛️ Architecture: $name ($id)';
  @override
  String get archShowLayers => '[Layer Structure (Layers)]';
  @override
  String get archShowNamingRules => '[Naming Rules]';
  @override
  String archExportSuccess(String id, String path) => '✅ Exported architecture "$id" to "$path"!';
  @override
  String archCreateSuccess(String id, String path) => '✅ Created local architecture boilerplate at "$path"!';
  @override
  String architectureAlreadyExists(String path) => '❌ Error: Architecture definition already exists: $path';
  @override
  String get missingArchitectureId => 'Please specify an architecture ID. Example: utakata arch show clean_architecture';
  @override
  String get missingOutputPath => 'Please specify an output path. Example: utakata arch export clean_architecture temp.yaml';

  // ─── other errors ───
  @override
  String guideGenerationFailed(String error) => 'Failed to generate guides: $error';
  @override
  String templatePathResolveFailed(String path) => 'Failed to resolve package template path: $path';
}

