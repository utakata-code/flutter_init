import 'cli_messages.dart';

/// 英語メッセージ実装
class EnMessages implements CliMessages {
  const EnMessages();

  // ─── command descriptions ───
  @override
  String get cmdCreateDesc => 'Create a new Flutter project';
  @override
  String get cmdFeatureDesc => 'Add a feature';
  @override
  String get cmdFeatureAddDesc => 'Add a single feature';
  @override
  String get cmdFeatureInitDesc =>
      'Bulk-generate all features from plan_architecture.yaml';
  @override
  String get cmdPlanDesc => 'plan.yaml (intent-level plan) commands';
  @override
  String get cmdScanDesc =>
      'Scan the current directory structure and save to YAML';
  @override
  String get cmdDiffDesc =>
      'Permanent alias for check (verify plan.yaml against the real structure)';
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
  @override
  String get optBrief => 'Lightweight mode (skip flutter analyze/version)';
  @override
  String get optWriteReport => 'Update project_status.yaml/md';

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

  // ─── core ───
  @override
  String get cmdCoreDesc => 'Generate Core directory structure';
  @override
  String get sectionCore => '🏗️ utakata core — Core directory generation';
  @override
  String coreDone(int count) => '✅ Generated $count Core module directories!';
  @override
  String coreModuleRow(String path) => '  ✅ $path';

  // ─── check (v0.7) ───
  @override
  String get optJson => 'Output as JSON';
  @override
  String get optFile => 'Filter violations to the given path only';
  @override
  String get namingViolationsHeader => '⚠️ Naming violations:';
  @override
  String get checkClean => '✅ Structure matches the plan (no violations)';
  @override
  String checkSummary(int missing, int extra, int naming) =>
      '⚠️ missing: $missing / extra: $extra / naming violations: $naming';
  @override
  String deprecatedAlias(String oldCmd, String newCmd) =>
      '⚠️  `utakata $oldCmd` is deprecated. Use `utakata $newCmd` instead.';

  // ─── apply (v0.7) ───
  @override
  String get cmdApplyDesc => 'Generate feature/core scaffolding missing from plan.yaml';
  @override
  String get optScope => 'Scope to generate (all|feature|core)';
  @override
  String get sectionApply => '🏗️ utakata apply — Generating structure';
  @override
  String applyFeatureRow(String path) => '  ✅ $path';
  @override
  String applyDone(int featureCount, int coreCount) =>
      '✅ Generated $featureCount feature(s), $coreCount core module(s)';
  @override
  String get applyNothingToDo => 'Nothing to generate (plan.yaml not found or empty)';

  // ─── plan adopt (v0.7) ───
  @override
  String get cmdPlanAdoptDesc => 'Detect unplanned features and append them to plan.yaml';
  @override
  String get sectionPlanAdopt => '🔍 utakata plan adopt — Detecting unplanned features';
  @override
  String get adoptNoneFound => 'No unplanned features found';
  @override
  String adoptCandidateRow(String permission, String name) => '  - $permission/$name';
  @override
  String adoptConfirm(String permission, String name) =>
      'Add "$permission/$name" to plan.yaml? [y/N] ';
  @override
  String adoptDone(int count) => '✅ Added $count feature(s) to plan.yaml';

  // ─── doc init (v0.8) ───
  @override
  String get cmdDocDesc => 'doc/ project workspace commands';
  @override
  String get cmdDocInitDesc => 'Create the doc/ workspace ahead of the app (pre-contract phase)';
  @override
  String get docInitDone => '✅ Created the doc/ workspace';
  @override
  String get docInitAlreadyExists => 'doc/ already exists';

  // ─── log (v0.8) ───
  @override
  String get cmdLogDesc => 'Structured client conversation log (human-only writes)';
  @override
  String get cmdLogAddDesc => 'Append one log entry';
  @override
  String get cmdLogShowDesc => 'Show log entries';
  @override
  String get cmdLogRenderDesc => 'Regenerate the Markdown log preview';
  @override
  String logAddDone(String id) => '✅ Recorded $id';
  @override
  String get logShowEmpty => 'No matching log entries found';
  @override
  String get logRenderDone => '✅ Preview regenerated';

  // ─── agree (v0.9) ───
  @override
  String get cmdAgreeDesc => 'Agreement tracking (client agreements, internal decisions)';
  @override
  String get cmdAgreeAddDesc => 'Append one agreement';
  @override
  String get cmdAgreeListDesc => 'List agreements';
  @override
  String get cmdAgreeStatusDesc => 'Update an agreement\'s status';
  @override
  String agreeAddDone(String id) => '✅ Recorded $id';
  @override
  String get agreeListEmpty => 'No agreements recorded';
  @override
  String agreeStatusDone(String id, String status) => '✅ Updated $id to $status';

  // ─── impl (v0.9) ───
  @override
  String get cmdImplDesc => 'Feature implementation plan management';
  @override
  String get cmdImplNewDesc => 'Create a new implementation plan';
  @override
  String get cmdImplListDesc => 'List implementation plans';
  @override
  String get cmdImplDoneDesc => 'Mark an implementation plan as done';
  @override
  String get cmdImplArchiveDesc => 'Move a done implementation plan to archive/';
  @override
  String implNewDone(String id, String path) => '✅ Created $id: $path';
  @override
  String get implListEmpty => 'No implementation plans found';
  @override
  String implDoneDone(String id) => '✅ Marked $id as done';
  @override
  String implArchiveDone(String id) => '✅ Moved $id to archive/';

  // ─── summary (v0.9) ───
  @override
  String get cmdSummaryDesc => 'Regenerate the marked sections of the project summary';
  @override
  String get summaryRenderDone => '✅ Regenerated the marked sections of summary.md';

  // ─── guide (v1.0) ───
  @override
  String get cmdGuideDesc => 'Browse reference knowledge (GUIDE etc.) and start customizing';
  @override
  String get cmdGuideListDesc => 'List available guides';
  @override
  String get cmdGuideShowDesc => 'Show a guide\'s content';
  @override
  String get cmdGuideEjectDesc => 'Eject a guide locally to start customizing';
  @override
  String get guideListEmpty => 'No guides found';
  @override
  String guideEjectDone(String id, String path) => '✅ Ejected $id: $path';
  @override
  String get missingGuideId => 'Please specify a guide ID';

  // ─── doctor (v1.0) ───
  @override
  String get cmdDoctorDesc => 'Diagnose environment/schema/layout and migrate';
  @override
  String get doctorOk => '✅ No issues found';
  @override
  String doctorIssueRow(String message) => '  ⚠️ $message';
  @override
  String get doctorMigrateNoneFound => 'Nothing to migrate';
  @override
  String doctorMigrateDone(int count) => '✅ Migrated $count item(s)';

  // ─── mcp (v1.1) ───
  @override
  String get cmdMcpDesc => 'Start the MCP server (stdio, read-only)';

  @override
  String get cmdClaudeDesc =>
      'Generate or repair the Claude Code integration (.claude/, .mcp.json, CLAUDE.md)';
  @override
  String get cmdClaudeInitDesc =>
      'Write .claude/ (skills, agent, settings) + .mcp.json + CLAUDE.md. '
      'Default repairs missing files only (existing ones are protected); --force regenerates';
  @override
  String get cmdSkillsDesc => 'Sync architecture-bundled SKILLs into .claude/skills/';
  @override
  String get cmdSkillsSyncDesc =>
      'Sync the skills list in utakata.yaml into .claude/skills/ (managed-marker protection)';
  @override
  String get cmdVaultDesc =>
      'Browse the personal knowledge vault (client-facing service know-how)';
  @override
  String get cmdVaultListDesc => 'List vault entries';
  @override
  String get cmdVaultShowDesc => 'Print a vault entry: vault show Google/GCP/Firebase';
  @override
  String get cmdVaultGetDesc => 'Fetch (or re-fetch) the vault from its configured url';
  @override
  String get cmdDocShowDesc =>
      'Print the reference for a config file: doc show config|plan (see doc list)';
  @override
  String get cmdDocListDesc => 'List the available documentation topics';
  @override
  String get cmdPlanExpandDesc =>
      'Materialize the auto-derived per-layer lists into plan.yaml (editable afterwards)';
  @override
  String get cmdPlanAddDesc =>
      'Add items to a layer list in plan.yaml: plan add <feature> <layer> <item...>';
  @override
  String get cmdPlanRemoveDesc =>
      'Remove an item from a layer list in plan.yaml: plan remove <feature> <layer> <item>';
  @override
  String get cmdGuideForDesc =>
      'Deterministically resolve the layer guide for a file path (fix-context for lint errors)';
  @override
  String get cmdArchGetDesc =>
      'Fetch the knowledge repo (the official utakata_arch_lib when knowledge_repo is unset)';
  @override
  String get cmdAgreeCorrectDesc => 'Correct (supersede) a past agreement';
  @override
  String get cmdAgreeReflectDesc =>
      'Record where an agreement was reflected (impl plan / spec)';
  @override
  String get cmdLogImportDesc =>
      'Import a Claude Code session transcript into doc/records/sessions/ (human-only)';

  @override
  String get optForceOverwrite =>
      'Also overwrite human-edited managed files (unmanaged files are never touched)';
  @override
  String get optForceRegenerate => 'Overwrite existing files (including CLAUDE.md)';
  @override
  String get optUpdateRef => 'Re-resolve the ref and update';
  @override
  String get optExpandDryRun => 'Show the result without writing';
  @override
  String get optExpandFeature => 'Limit to a single feature';
  @override
  String get optJsonOutput => 'Output as JSON';
  @override
  String get optArchAuto => 'Resolved from utakata.yaml / plan.yaml when omitted';
  @override
  String get optImportList => 'List this project\'s sessions';
  @override
  String get optImportSession => 'Import the session with this id (prefix match)';
  @override
  String get optImportLast => 'Import the most recent session';
  @override
  String get optImportFull =>
      'Include thinking / tool_use as well (tool_result is always excluded)';
  @override
  String get optSkipConfirm => 'Skip the confirmation prompt';
  @override
  String get optMigrate => 'Migrate the legacy layout to the current one';
  @override
  String get optFeatureTemplate => 'Apply a feature preset template by id';
  @override
  String get optLogAt => 'e.g. "6/30 17:41" (defaults to now)';

  // ─── feature --template (v1.0) ───
  @override
  String get missingTemplateId => 'Please specify a template ID';
  @override
  String templateNotFound(String id) => 'Template "$id" was not found';
  @override
  String templateApplied(String id, String featureName) =>
      '✅ Applied template "$id": $featureName';
}

