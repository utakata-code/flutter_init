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

  Future<void> execute(String projectDir) async {
    await _ensureDir('$projectDir/.claude/skills/utakata-structure');
    await _ensureDir('$projectDir/.claude/skills/utakata-client-context');
    await _ensureDir('$projectDir/.claude/agents');

    await _writeFile('$projectDir/.mcp.json', _mcpJson());
    await _writeFile('$projectDir/.claude/settings.json', _settingsJson());
    await _writeFile(
      '$projectDir/.claude/skills/utakata-structure/SKILL.md',
      _structureSkill(),
    );
    await _writeFile(
      '$projectDir/.claude/skills/utakata-client-context/SKILL.md',
      _clientContextSkill(),
    );
    await _writeFile(
      '$projectDir/.claude/agents/structure-auditor.md',
      _structureAuditorAgent(),
    );

    final claudeMdPath = '$projectDir/CLAUDE.md';
    final fileExists = _fileExists;
    if (fileExists == null || !fileExists(claudeMdPath)) {
      final config = await _configRepo?.read(projectDir);
      await _writeFile(claudeMdPath, _claudeMd(config));
    }
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
      ..writeln('- `utakata.yaml` — プロジェクトのマスター設定');

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
          { "type": "command", "command": "utakata check --quick --json" }
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
  utakata プロジェクトの構造を検証・生成するスキル。
  「構造をチェックして」「feature を生成して」「check/apply を実行して」時に使用。
---

# utakata 構造スキル

- 実装前に `utakata check --json` で現状の違反を確認する
- feature を新規追加する場合は `utakata plan adopt` で plan.yaml に登録してから
  `utakata apply --scope feature` を実行する
- 命名規則違反やディレクトリの過不足は `utakata check` の出力にある GUIDE 抜粋を参照する
- MCP が利用できない場合は `utakata check --json` を Bash 経由で直接呼び出す
''';

  String _clientContextSkill() => '''
---
name: utakata-client-context
description: |
  お客様との会話・合意を参照して要件の根拠を確認するスキル。
  「この要件の出典は？」「お客様と何を合意した？」時に使用。
---

# utakata クライアントコンテキストスキル

- 会話ログは `utakata log show --thread <トピック>` で参照する(読み取り専用)
- 合意は `utakata agree list` で確認する。金額・ステータス・出典 MSG ID が含まれる
- **書き込みは行わない**: `doc/records/**` への編集は人間のコマンド経由でのみ行われる。
  記録が必要な場合は `utakata log add` / `utakata agree add` の実行を人間に提案する
''';

  String _structureAuditorAgent() => '''
---
name: structure-auditor
description: utakata check の結果を読み、構造・命名違反の修復を提案するエージェント
tools: Bash, Read, Edit
---

`utakata check --json` を実行し、missing/extra/namingViolations を解析して
修復方針を提案する。命名規則違反は該当ファイルをリネームし、missing は
`utakata apply` で生成できるか確認する。plan.yaml 自体の変更は提案に留め、
実行は人間の確認を経てから行う。
''';
}
