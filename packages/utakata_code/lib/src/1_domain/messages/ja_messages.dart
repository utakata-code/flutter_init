import 'cli_messages.dart';

/// 日本語メッセージ実装
class JaMessages implements CliMessages {
  const JaMessages();

  // ─── コマンド description ───
  @override
  String get cmdCreateDesc => 'Flutter プロジェクトを新規作成する';
  @override
  String get cmdFeatureDesc => 'フィーチャーの追加・一括生成を行う';
  @override
  String get cmdFeatureAddDesc => 'フィーチャーを 1 件追加する';
  @override
  String get cmdFeatureInitDesc => 'plan_architecture.yaml から全フィーチャーを一括生成する';
  @override
  String get cmdPlanDesc => 'feature_request.yaml からアーキテクチャ計画書を生成する';
  @override
  String get cmdScanDesc => '現在のディレクトリ構造をスキャンして YAML に保存する';
  @override
  String get cmdDiffDesc => 'plan_architecture.yaml と現在の構造の差分を表示する';
  @override
  String get cmdCheckDesc => 'アーキテクチャの健全性チェックを行う（差分があれば exit 1）';
  @override
  String get cmdStatusDesc => 'プロジェクトの現在の状態を総合表示する';
  @override
  String get cmdRunnerDesc => '仕様駆動開発を支援する Flutter CLI ツール';

  // ─── コマンドランナー ───
  @override
  String get versionHelp => 'バージョンを表示する';

  // ─── オプション help ───
  @override
  String get optOrg => 'パッケージ組織名 (例: com.example)';
  @override
  String get optPlatforms => '対象プラットフォーム (カンマ区切り)';
  @override
  String get optDescription => 'プロジェクトの説明';
  @override
  String get optArch => '使用するアーキテクチャ (例: clean_architecture)';
  @override
  String get optEntity => 'エンティティ名（省略時はフィーチャー名と同じ）';
  @override
  String get optPermission => '権限レベル';
  @override
  String get optYes => '確認プロンプトをスキップ';
  @override
  String get optDryRun => '実際には生成せず対象を確認するだけ';
  @override
  String get optBrief => '軽量モード(flutter analyze/version を呼ばない)';
  @override
  String get optWriteReport => 'project_status.yaml/md を更新する';

  // ─── Logger.section ───
  @override
  String sectionCreate(String name) => '🚀 utakata create — $name';
  @override
  String get sectionPlan => '📝 utakata plan — 計画ファイルの生成';
  @override
  String get sectionScan => '📸 utakata scan — 実績スナップショット生成';
  @override
  String get sectionDiff => '⚖️ utakata diff — アーキテクチャ差分検証';
  @override
  String get sectionCheck => '🔍 utakata check — アーキテクチャ検証';
  @override
  String get sectionStatus => '📊 utakata status — プロジェクト状態確認';
  @override
  String sectionFeatureAdd(String name) => '✨ utakata feature add — $name';
  @override
  String sectionFeatureInit(bool dryRun) =>
      '🚀 utakata feature init${dryRun ? ' (dry-run)' : ''}';

  // ─── 共通 ───
  @override
  String get cancel => 'キャンセルしました。';

  // ─── エラー入力 ───
  @override
  String get missingAppName => 'アプリ名を指定してください。例: utakata create my_app';
  @override
  String get missingFeatureName =>
      'フィーチャー名を指定してください。例: utakata feature add memo';
  @override
  String confirmGenerate(String path) => '"$path" に生成しますか？ (y/N)';
  @override
  String projectCreated(String name) => '✅ プロジェクト "$name" を生成しました！';

  // ─── plan ───
  @override
  String get planMissingFeaturesKey =>
      'feature_request.yaml に features キーがありません。';
  @override
  String planDone(int count) => '計画書を生成しました（$count フィーチャー）';

  // ─── feature add ───
  @override
  String featureAddPath(String path) => '  パス: $path';
  @override
  String featureAddDone(String name) => 'フィーチャー "$name" を生成しました！';
  @override
  String get featureAddCancel => 'キャンセルしました。';

  // ─── feature init ───
  @override
  String get featureInitNone => '生成対象のフィーチャーが見つかりませんでした。';
  @override
  String featureInitDone(int count) => '$count 件のフィーチャーを生成しました！';
  @override
  String featureDryRunRow(String path) => '[DRY] $path';

  // ─── scan ───
  @override
  String get scanDone => 'スナップショットを生成しました';

  // ─── diff ───
  @override
  String get diffClean => '差分なし！ 計画と実績が完全に一致しています。';
  @override
  String diffSummary(int missing, int extra) => 'Missing: $missing, Extra: $extra';
  @override
  String get diffMissingHeader => 'Missing（計画にあるが未実装）:';
  @override
  String get diffExtraHeader => 'Extra（実績にあるが計画外）:';

  // ─── check ───
  @override
  String get checkOk => 'アーキテクチャは健全です！';
  @override
  String get checkFail =>
      'アーキテクチャに問題があります。utakata diff で詳細を確認してください。';
  @override
  String checkMissingRow(String path) => '[Missing] $path';

  // ─── status ───
  @override
  String get statusFlutterVersionHeader => '--- Flutter Version ---';
  @override
  String get statusLintHeader => '--- Lint Analysis ---';
  @override
  String get statusLintOk => '問題なし';
  @override
  String get statusArchHeader => '--- Architecture Diff ---';
  @override
  String get statusNoPlan =>
      'plan_architecture.yaml が見つかりません。utakata plan を先に実行してください。';
  @override
  String get statusDiffClean => '計画と実績が一致しています！';

  // ─── エラー ───
  @override
  String featureRequestNotFound(String path) =>
      '$path が見つかりません。仕様書を作成してください。';
  @override
  String planNotFound(String path) =>
      '$path が見つかりません。先に utakata plan を実行してください。';
  @override
  String currentStructureNotFound(String path) =>
      '$path が見つかりません。先に utakata scan を実行してください。';
  @override
  String notFlutterProject(String dir) =>
      '$dir は Flutter プロジェクトではありません。プロジェクトのルートで実行してください。';
  @override
  String get flutterNotFound =>
      'flutter コマンドが見つかりません。'
      'FLUTTER_PATH 環境変数にフルパスを設定してください。'
      '例: export FLUTTER_PATH=/path/to/flutter/bin/flutter';
  @override
  String yamlParseFailed(String path) => '$path の YAML 解析に失敗しました。';
  @override
  String get flutterCreateFailed => 'flutter create に失敗しました。';
  @override
  String get buildRunnerFailed => 'build_runner の実行に失敗しました。';

  // ─── add_feature_usecase ───
  @override
  String layerDirCreateFailed(String path) => 'ディレクトリの作成に失敗しました: $path';
  @override
  String templateExpandFailed(String path) => 'テンプレートの展開に失敗しました: $path';

  // ─── validate ───
  @override
  String get cmdValidateDesc =>
      '命名規則とディレクトリ構造の違反を検出する';
  @override
  String get sectionValidate => '🔎 utakata validate — 命名規則・構造検証';
  @override
  String get validateOk => '命名規則・ディレクトリ構造ともに問題ありません！';
  @override
  String get validateNamingHeader => '【命名規則違反】';
  @override
  String get validateStructureHeader => '【ディレクトリ構造違反】';
  @override
  String validateNamingViolation(String file, String expected) =>
      '  ❌ $file\n     期待: $expected';
  @override
  String validateMissingDir(String path) => '  Missing: $path';
  @override
  String validateExtraDir(String path) => '  Extra:   $path';
  @override
  String validateSummary(int naming, int missing, int extra) =>
      '命名違反: $naming 件 / Missing: $missing 件 / Extra: $extra 件';

  // ─── arch subcommands ───
  @override
  String get cmdArchDesc => 'アーキテクチャの確認・エクスポート・カスタム作成を行う';
  @override
  String get cmdArchListDesc => '利用可能なアーキテクチャ定義の一覧を表示する';
  @override
  String get cmdArchShowDesc => '指定したアーキテクチャの定義、命名規則、および層構造のツリーを表示する';
  @override
  String get cmdArchExportDesc => '指定したアーキテクチャ定義の生 YAML ファイルをエクスポートする';
  @override
  String get cmdArchCreateDesc => 'プロジェクトのローカルにカスタムアーキテクチャ定義のボイラープレートを作成する';
  @override
  String get archListHeader => '利用可能なアーキテクチャ定義一覧:';
  @override
  String archShowHeader(String id, String name) => '🏛️ アーキテクチャ: $name ($id)';
  @override
  String get archShowLayers => '【レイヤー構造 (Layers)】';
  @override
  String get archShowNamingRules => '【命名規則 (Naming Rules)】';
  @override
  String archExportSuccess(String id, String path) => '✅ アーキテクチャ "$id" の定義を "$path" にエクスポートしました！';
  @override
  String archCreateSuccess(String id, String path) => '✅ ローカルアーキテクチャ定義のボイラープレートを "$path" に作成しました！';
  @override
  String architectureAlreadyExists(String path) => '❌ エラー: アーキテクチャ定義がすでに存在します: $path';
  @override
  String get missingArchitectureId => 'アーキテクチャ ID を指定してください。例: utakata arch show clean_architecture';
  @override
  String get missingOutputPath => 'エクスポート先のパスを指定してください。例: utakata arch export clean_architecture temp.yaml';

  // ─── その他エラー ───
  @override
  String guideGenerationFailed(String error) => 'ガイド生成に失敗しました: $error';
  @override
  String templatePathResolveFailed(String path) => 'パッケージテンプレートのパス解決に失敗しました: $path';

  // ─── core ───
  @override
  String get cmdCoreDesc => 'Core ディレクトリ構造を生成する';
  @override
  String get sectionCore => '🏗️ utakata core — Core ディレクトリ生成';
  @override
  String coreDone(int count) => '✅ $count 件の Core モジュールディレクトリを生成しました！';
  @override
  String coreModuleRow(String path) => '  ✅ $path';

  // ─── check (v0.7) ───
  @override
  String get optJson => 'JSON 形式で出力する';
  @override
  String get optFile => '指定したパス配下の違反のみに絞り込む';
  @override
  String get namingViolationsHeader => '⚠️ 命名規則違反:';
  @override
  String get checkClean => '✅ 構造は計画と一致しています(違反なし)';
  @override
  String checkSummary(int missing, int extra, int naming) =>
      '⚠️ missing: $missing / extra: $extra / naming violations: $naming';
  @override
  String deprecatedAlias(String oldCmd, String newCmd) =>
      '⚠️  `utakata $oldCmd` は非推奨です。`utakata $newCmd` を使用してください。';

  // ─── apply (v0.7) ───
  @override
  String get cmdApplyDesc => 'plan.yaml から未生成の feature/core を生成する';
  @override
  String get optScope => '生成範囲(all|feature|core)';
  @override
  String get sectionApply => '🏗️ utakata apply — 構造の生成';
  @override
  String applyFeatureRow(String path) => '  ✅ $path';
  @override
  String applyDone(int featureCount, int coreCount) =>
      '✅ feature: $featureCount 件、core: $coreCount 件を生成しました';
  @override
  String get applyNothingToDo => '生成対象がありません(plan.yaml が見つからないか、空です)';

  // ─── plan adopt (v0.7) ───
  @override
  String get cmdPlanAdoptDesc => '未計画の feature を検出し plan.yaml へ追記する';
  @override
  String get sectionPlanAdopt => '🔍 utakata plan adopt — 未計画 feature の検出';
  @override
  String get adoptNoneFound => '未計画の feature は見つかりませんでした';
  @override
  String adoptCandidateRow(String permission, String name) => '  - $permission/$name';
  @override
  String adoptConfirm(String permission, String name) =>
      '"$permission/$name" を plan.yaml に追記しますか？ [y/N] ';
  @override
  String adoptDone(int count) => '✅ $count 件の feature を plan.yaml に追記しました';

  // ─── doc init (v0.8) ───
  @override
  String get cmdDocDesc => 'doc/ 案件ワークスペース操作コマンド群';
  @override
  String get cmdDocInitDesc => 'doc/ 案件ワークスペースを先行作成する(契約前フェーズ用)';
  @override
  String get docInitDone => '✅ doc/ ワークスペースを作成しました';
  @override
  String get docInitAlreadyExists => 'doc/ は既に存在します';

  // ─── log (v0.8) ───
  @override
  String get cmdLogDesc => 'お客様会話ログの構造化記録(人間専用)';
  @override
  String get cmdLogAddDesc => '会話ログを1件追記する';
  @override
  String get cmdLogShowDesc => '会話ログを表示する';
  @override
  String get cmdLogRenderDesc => '会話ログの Markdown プレビューを再生成する';
  @override
  String logAddDone(String id) => '✅ $id を記録しました';
  @override
  String get logShowEmpty => '該当する会話ログが見つかりませんでした';
  @override
  String get logRenderDone => '✅ プレビューを再生成しました';

  // ─── agree (v0.9) ───
  @override
  String get cmdAgreeDesc => '合意トラッキング(お客様合意・内部決定)';
  @override
  String get cmdAgreeAddDesc => '合意を1件追記する';
  @override
  String get cmdAgreeListDesc => '合意の一覧を表示する';
  @override
  String get cmdAgreeStatusDesc => '合意の状態を更新する';
  @override
  String agreeAddDone(String id) => '✅ $id を記録しました';
  @override
  String get agreeListEmpty => '合意が記録されていません';
  @override
  String agreeStatusDone(String id, String status) => '✅ $id の状態を $status に更新しました';

  // ─── impl (v0.9) ───
  @override
  String get cmdImplDesc => 'feature 実装計画の管理';
  @override
  String get cmdImplNewDesc => '実装計画書を新規作成する';
  @override
  String get cmdImplListDesc => '実装計画の一覧を表示する';
  @override
  String get cmdImplDoneDesc => '実装計画を完了にする';
  @override
  String get cmdImplArchiveDesc => '完了済みの実装計画を archive/ へ移動する';
  @override
  String implNewDone(String id, String path) => '✅ $id を作成しました: $path';
  @override
  String get implListEmpty => '実装計画が見つかりませんでした';
  @override
  String implDoneDone(String id) => '✅ $id を完了にしました';
  @override
  String implArchiveDone(String id) => '✅ $id を archive/ へ移動しました';

  // ─── summary (v0.9) ───
  @override
  String get cmdSummaryDesc => '案件整理サマリーのマーカー区間を再生成する';
  @override
  String get summaryRenderDone => '✅ summary.md のマーカー区間を再生成しました';

  // ─── guide (v1.0) ───
  @override
  String get cmdGuideDesc => '参照型ナレッジ(GUIDE 等)の閲覧・カスタム開始';
  @override
  String get cmdGuideListDesc => '利用可能なガイドの一覧を表示する';
  @override
  String get cmdGuideShowDesc => 'ガイドの内容を表示する';
  @override
  String get cmdGuideEjectDesc => 'ガイドをローカルへ書き出しカスタムを開始する';
  @override
  String get guideListEmpty => 'ガイドが見つかりませんでした';
  @override
  String guideEjectDone(String id, String path) => '✅ $id を書き出しました: $path';
  @override
  String get missingGuideId => 'ガイド ID を指定してください';

  // ─── doctor (v1.0) ───
  @override
  String get cmdDoctorDesc => '環境・スキーマ・レイアウトの診断と移行';
  @override
  String get doctorOk => '✅ 問題は見つかりませんでした';
  @override
  String doctorIssueRow(String message) => '  ⚠️ $message';
  @override
  String get doctorMigrateNoneFound => '移行対象が見つかりませんでした';
  @override
  String doctorMigrateDone(int count) => '✅ $count 件を移行しました';

  // ─── mcp (v1.1) ───
  @override
  String get cmdMcpDesc => 'MCP サーバーを起動する(stdio・読み取り専用)';

  // ─── feature --template (v1.0) ───
  @override
  String get missingTemplateId => 'テンプレート ID を指定してください';
  @override
  String templateNotFound(String id) => 'テンプレート "$id" が見つかりませんでした';
  @override
  String templateApplied(String id, String featureName) =>
      '✅ テンプレート "$id" を適用しました: $featureName';
}

