import '../1_entities/config/utakata_config_entity.dart';
import '../2_repositories/config_repository.dart';

/// `create` 時に `.claude/` と `.mcp.json` を生成するユースケース(仕様書 §11)。
///
/// フックは「速い検査ほど早いフックに」の原則で構成する:
/// PreToolUse はパス判定のみ(utakata を起動しない)、PostToolUse は
/// 単一ファイル粒度の check、Stop はブロックしない警告のみ。
///
/// v1.0.0(S1)から `CLAUDE.md` も生成する。`utakata.yaml` に `team:` が
/// 定義されていれば「登場人物と役割」節を含め、AI が誰の決定に従うべきかを
/// セッション冒頭から把握できるようにする。既存の CLAUDE.md は上書きしない。
class GenerateClaudeIntegrationUsecase {
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;
  final bool Function(String path)? _fileExists;
  final ConfigRepository? _configRepo;

  const GenerateClaudeIntegrationUsecase({
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
    bool Function(String path)? fileExists,
    ConfigRepository? configRepo,
  })  : _writeFile = writeFile,
        _ensureDir = ensureDir,
        _fileExists = fileExists,
        _configRepo = configRepo;

  /// [skipExisting] が true の場合、既に存在するファイルには一切触れない
  /// (`claude init` の既定 = 欠けているものだけ補修する安全モード)。
  /// false(create の既定・`claude init --force`)は CLAUDE.md 以外を上書きする。
  /// [forceClaudeMd] は既存 CLAUDE.md も上書きする(`claude init --force` 専用)。
  ///
  /// 書き込んだ相対パスの一覧を返す。
  Future<List<String>> execute(
    String projectDir, {
    bool skipExisting = false,
    bool forceClaudeMd = false,
  }) async {
    await _ensureDir('$projectDir/.claude/skills/utakata-structure');
    await _ensureDir('$projectDir/.claude/skills/utakata-client-context');
    await _ensureDir('$projectDir/.claude/skills/utakata-impl-flow');
    await _ensureDir('$projectDir/.claude/skills/utakata-client-explainer');
    await _ensureDir('$projectDir/.claude/agents');

    final written = <String>[];
    Future<void> write(String relativePath, String content) async {
      final path = '$projectDir/$relativePath';
      final fileExists = _fileExists;
      if (skipExisting && fileExists != null && fileExists(path)) return;
      await _writeFile(path, content);
      written.add(relativePath);
    }

    await write('.mcp.json', _mcpJson());
    await write('.claude/settings.json', _settingsJson());
    await write('.claude/skills/utakata-structure/SKILL.md', _structureSkill());
    await write(
        '.claude/skills/utakata-client-context/SKILL.md', _clientContextSkill());
    await write('.claude/skills/utakata-impl-flow/SKILL.md', _implFlowSkill());
    await write('.claude/skills/utakata-client-explainer/SKILL.md',
        _clientExplainerSkill());
    await write('.claude/agents/structure-auditor.md', _structureAuditorAgent());

    final claudeMdPath = '$projectDir/CLAUDE.md';
    final fileExists = _fileExists;
    if (forceClaudeMd || fileExists == null || !fileExists(claudeMdPath)) {
      final config = await _configRepo?.read(projectDir);
      await _writeFile(claudeMdPath, _claudeMd(config));
      written.add('CLAUDE.md');
    }
    return written;
  }

  String _claudeMd(UtakataConfig? config) {
    final buffer = StringBuffer()
      ..writeln('# utakata プロジェクト')
      ..writeln()
      ..writeln('このプロジェクトは utakata CLI(仕様駆動開発)で管理されています。')
      ..writeln()
      ..writeln('## まず読むもの')
      ..writeln()
      ..writeln('- `doc/summary.md` — 案件整理サマリー(合意の台帳。ビジネス上の決定事項)')
      ..writeln('- `doc/specs/plan.yaml` — feature の意図レベル計画')
      ..writeln('- `doc/records/` — お客様との会話ログ・合意(**読み取り専用**。'
          '書き込みは人間が `utakata log add` / `utakata agree add` で行う)')
      ..writeln('- `utakata.yaml` — プロジェクトのマスター設定')
      ..writeln()
      ..writeln('設定ファイルの書き方は `utakata doc show plan` / '
          '`utakata doc show config` で確認できる(推測で書かないこと)。');

    final team = config?.team;
    if (team != null && !team.isEmpty) {
      buffer
        ..writeln()
        ..writeln('## 登場人物と役割')
        ..writeln();
      if (team.client != null) buffer.writeln('- **お客様**: ${team.client}');
      if (team.developer != null) buffer.writeln('- **開発者**: ${team.developer}');
      for (final agent in team.aiAgents) {
        buffer.writeln('- **AI (${agent.id})**: ${agent.role}');
      }
      buffer
        ..writeln()
        ..writeln('仕様に関わる判断はお客様・開発者に確認し、AI が独断で決定しないこと。');
    }

    buffer
      ..writeln()
      ..writeln('## 構造ルール')
      ..writeln()
      ..writeln('- 実装前に `utakata check --json` で構造違反を確認する')
      ..writeln('- feature 追加は `utakata plan adopt` → `utakata apply --scope feature`')
      ..writeln('- ファイルを手動作成せず、utakata CLI で構造を拡張する')
      ..writeln('- コミット前に `utakata check` を実行する');

    return buffer.toString();
  }

  String _mcpJson() => '''
{
  "mcpServers": {
    "utakata": {
      "command": "utakata",
      "args": ["mcp"]
    }
  }
}
''';

  String _settingsJson() => '''
{
  "permissions": {
    "deny": [
      "Edit(doc/records/**)",
      "Write(doc/records/**)",
      "Edit(doc/preview/**)",
      "Write(doc/preview/**)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "utakata status --brief" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "utakata check --json" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "utakata status --brief --write-report" }
        ]
      }
    ]
  }
}
''';

  String _structureSkill() => '''
---
name: utakata-structure
description: |
  utakata プロジェクトの構造ワークフロー(計画→生成→検証)。
  feature の追加・実装開始・構造やレイヤーの確認・命名/構造エラーの修正・
  コミット前チェックのとき、コードやディレクトリを手で作る前に必ず使用。
---

# utakata 構造ワークフロー

このプロジェクトの `lib/` 構造は utakata CLI が管理する。
**レイヤーディレクトリやファイルを手動で作らず、必ず以下のフローに従う。**

## 基本フロー(計画 → 生成 → 検証)

1. **計画**: feature は `doc/specs/plan.yaml` に宣言する(name / permission /
   entities)。CLI でやるなら `utakata feature add <name> --entity <e> --permission user`
   (`--template <id>` で feature プリセットも適用できる)
2. **生成**: `utakata apply --scope feature` — plan.yaml が宣言していて `lib/` に
   無いものだけを生成する(`--dry-run` で事前確認可)
3. **検証**: `utakata check --json` — 不足・余分・命名規則違反を1回で報告する。
   **コミット前に必ず `utakata check` を実行する**

## 層ごとの過不足を調整したいとき

- feature を宣言しても全層が必須になるわけではない。`plan.yaml` の `layers:` で
  必要な層だけを宣言できる(空リスト `[]` = その層は不要)
- `utakata plan expand` — 自動導出されている構成を plan.yaml に書き出す
- `utakata plan add <feature> <layer> <item>` / `plan remove ...` — 1項目ずつ増減

## すでに書いたコードが plan に無いとき

- `utakata plan adopt` — `lib/features/` にあるが plan.yaml に無い feature を
  検出して追記する(書式保持)。plan.yaml を手で書き換えるより先にこれを使う

## エラー・違反を直すとき

- 命名/構造違反や lint エラーが出たファイルは
  `utakata guide for <file> --json` で**該当レイヤーのガイドを取得してから**直す
- レイヤーの役割・依存方向は `utakata arch show <arch_id>` で確認する
- ガイド一覧は `utakata guide list`、個別表示は `utakata guide show <layer_path>`

## 設定ファイルの書き方が分からないとき

- `utakata doc show plan` — plan.yaml(features / entities / layers)の書き方
- `utakata doc show config` — utakata.yaml の書き方
- MCP なら `doc_get` ツール(topic: plan | config)
- **推測で YAML を書かず、必ずこれで書式を確認する**

## 設定の優先順位

- マスター設定は `utakata.yaml`(`project.architecture` は plan.yaml より優先)。
  内容は MCP の `config_get`、または直接読んで確認する
- MCP ツール(`check_run`・`structure_get`・`plan_get`・`guide_for_file` 等)が
  使えない場合は同名機能を Bash の `utakata` コマンドで代替する
''';

  String _clientContextSkill() => '''
---
name: utakata-client-context
description: |
  お客様との会話・合意・過去セッションを参照して要件の根拠を確認するスキル。
  「この要件の出典は？」「お客様と何を合意した？」「誰の決定に従う？」
  「仕様の背景は？」のとき、および doc/records/ に触れる前に必ず使用。
---

# utakata クライアントコンテキストスキル

`doc/records/` はこの案件の**ビジネス上の正史**(お客様との会話・合意・過去セッション)。

## 参照方法(すべて読み取り専用)

- 会話ログ: `utakata log show [--thread <トピック>] [--tag <タグ>] [--date <日付>]`
- 合意: `utakata agree list [--unreflected]` — ID・ステータス・タイトル・金額付き。
  出典 MSG ID は `doc/records/agreements.jsonl` の記録と `utakata summary` が
  再生成する `doc/summary.md` の「参照:」行で確認する。
  未反映(--unreflected)の合意は実装に落ちていない決定事項なので特に注意する
- 誰の決定に従うか: MCP `config_get`(または `utakata.yaml` の `team:`)。
  仕様の変更・解釈は team に定義された決定権者に確認し、AI が独断で決めない
- 過去の開発セッション記録: `doc/records/sessions/`(人間が取り込んだもの)
- 人間向けプレビューは `doc/preview/` にあるが、正本は常に `doc/records/` の JSONL

## 絶対ルール: AI は記録に書き込まない

- `doc/records/**` と `doc/preview/**` への Edit/Write は deny 設定で拒否される
- 記録が必要になったら、人間に次のコマンドの実行を**提案**する:
  - 会話の記録: `utakata log add "..." -s client|developer`
  - 合意の記録: `utakata agree add --title "..." --kind client_agreement`
  - セッションの取り込み: `utakata log import claude-session --last`
- `doc/summary.md` の合意台帳区間(`<!-- utakata:begin agreements -->`)は
  `utakata summary` が再生成する。マーカー内は手で編集しない
''';

  String _implFlowSkill() => '''
---
name: utakata-impl-flow
description: |
  feature 単位の実装計画(impl plan)のライフサイクル管理。
  feature の実装を開始する・実装方針を検討する・実装を完了する・
  「どの feature が進行中？」のときに使用。
---

# utakata 実装計画フロー

規模のある feature は、コードを書く前に feature ごとの実装計画を作る
(`utakata.yaml` の `enforcement.impl_plan: "on"` が既定)。

## ライフサイクル

1. **着手前**: `utakata impl new <feature> [--agreement <AGR-id>] [--spec <path>]`
   — `doc/impl/PLAN-NNNN_<feature>.md` が発行される。根拠になった合意が
   あれば `--agreement` で紐づける
2. **実装中**: 技術選定の理由・試行錯誤・途中の判断は**その feature の PLAN
   ファイルの本文に書く**(他の feature の文脈と混ぜない = コンテキスト分離)。
   frontmatter(機械管理部分)は編集しない
3. **完了**: `utakata impl done <PLAN-id>` → 参照しなくなったら
   `utakata impl archive <PLAN-id>`(`doc/impl/archive/` へ退避)
4. **状況確認**: `utakata impl list` — 進行中/完了の一覧

## 注意

- `doc/impl/` は AI も編集できる(deny 対象は `doc/records/**` と `doc/preview/**`)。
  ただし本文の追記に留め、既存の記述を書き換えない
- 実装が仕様やお客様の合意に関わる場合は、着手前に utakata-client-context
  スキルの手順で根拠を確認する
''';

  String _clientExplainerSkill() => """
---
name: utakata-client-explainer
description: |
  お客様向けの説明文(アカウント取得のお願い・技術スタックの概要説明・
  料金や審査の案内)を作成するスキル。
  「Apple Developer の取得手順を説明して」「Firebase の料金をお客様に説明したい」
  「必要なアカウントを案内する文面を作って」のときに使用。
---

# お客様向け説明文の作成

外部サービス(Apple / Google / LINE 等)の取得手順・料金・審査要否は
**Vault に蓄積された検証済みナレッジ**を根拠にする。記憶だけで書かない。

## 手順

1. `utakata vault list` — 使えるエントリを確認する(MCP なら `vault_list`)
2. `utakata vault show <id>` — 該当サービスの本文を読む(MCP なら `vault_get`)
3. 読んだ内容をもとに、**その案件のお客様に合わせて**説明文を書く

## Vault の読み方

各エントリは次の構成になっている:

- **概要** — 非エンジニアにも通じる説明。ここを土台にする
- **アカウント取得手順** — 手順・料金・審査有無・所要日数
- **深掘り調査・検証済みの主張** — `確認した現在日時` と公式 URL 付きの検証記録。
  **料金・審査基準・仕様はここを必ず確認する**
- **参考リンク** — 補助情報

## 守ること

- **検証日時を確認する**: Vault の記述には `確認した現在日時` がある。日付が古く、
  料金や仕様など変わりやすい内容なら、その旨を添えるか人間に再確認を促す
- **Vault に無いことを断定しない**: 根拠が無い項目は「確認します」と書くか、
  人間に調査を依頼する。推測で料金や審査要否を書かない
- **Vault に書き込まない**: 知識の追記は人間が Vault リポジトリ側で行う
- **送信も人間が行う**: 生成した文面は下書き。送った後の記録は人間が
  `utakata log add "..." -s developer` (下書き段階なら `--draft`)で行う
- 合意事項(金額・仕様)が生じたら `utakata agree add` の実行を人間に提案する
""";

  String _structureAuditorAgent() => '''
---
name: structure-auditor
description: utakata check の結果を読み、構造・命名違反の修復を提案するエージェント
tools: Bash, Read, Edit
---

`utakata check --json` を実行し、missing/extra/namingViolations を解析して
修復方針を提案する。違反ファイルは `utakata guide for <file> --json` で該当
レイヤーのガイドを取得してから直す。命名規則違反は該当ファイルをリネームし、
missing は `utakata apply` で生成できるか確認する。plan.yaml 自体の変更は
`utakata plan adopt` の提案に留め、実行は人間の確認を経てから行う。
''';
}
