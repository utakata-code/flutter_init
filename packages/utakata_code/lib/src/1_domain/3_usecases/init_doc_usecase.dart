/// `utakata doc init` — Flutter プロジェクト作成前に `doc/` ワークスペースを
/// 先行作成するユースケース(契約前フェーズの一級市民化。仕様書 §4)。
class InitDocUsecase {
  final Future<void> Function(String path) _ensureDir;
  final Future<void> Function(String path, String content) _writeFile;
  final bool Function(String path) _fileExists;

  const InitDocUsecase({
    required Future<void> Function(String path) ensureDir,
    required Future<void> Function(String path, String content) writeFile,
    required bool Function(String path) fileExists,
  })  : _ensureDir = ensureDir,
        _writeFile = writeFile,
        _fileExists = fileExists;

  /// 既に存在していれば false、新規作成したら true を返す。
  Future<bool> execute(String projectDir) async {
    final utakataYamlPath = '$projectDir/utakata.yaml';
    if (_fileExists(utakataYamlPath)) {
      return false;
    }

    for (final dir in [
      '$projectDir/doc/specs',
      '$projectDir/doc/records/log',
      '$projectDir/doc/preview',
      '$projectDir/doc/impl/archive',
      '$projectDir/doc/knowledge',
      '$projectDir/doc/archive',
    ]) {
      await _ensureDir(dir);
    }

    await _writeFile(utakataYamlPath, _defaultUtakataYaml());
    await _writeFile('$projectDir/doc/summary.md', _defaultSummaryMd());

    return true;
  }

  String _defaultUtakataYaml() => '''
# utakata プロジェクト設定(マスターファイル)
# このファイルがプロジェクト全体のルールと座組を定義する。
schema: 1

project:
  architecture: clean_architecture
  # リモートナレッジリポジトリ(オプトイン。未指定なら同梱テンプレートを使用)
  # knowledge_repo:
  #   url: "https://github.com/utakata-code/utakata_arch_lib.git"
  #   ref: "v1.0.0"

# .claude/skills/ に同期する SKILL の有効リスト(utakata skills sync)
# skills:
#   - utakata-structure

# 登場人物と役割(AI が「誰の決定に従い、誰に判断を仰ぐか」を把握するための定義)
# team:
#   client: "お客様の名前(要件の決定権者。仕様変更はこの人の合意が必要)"
#   developer: "開発者の名前(アーキテクチャの責任者。コードの最終レビューを行う)"
#   ai_agents:
#     - id: feature-builder
#       role: "実装担当。plan.yaml と層ごとのガイドを読み込みコードを生成する。"

enforcement:
  impl_plan: "on"
records:
  git: commit
lang: ja
''';

  String _defaultSummaryMd() => '''
# 案件整理サマリー

<!-- utakata:begin agreements -->
<!-- utakata:end -->
''';
}
