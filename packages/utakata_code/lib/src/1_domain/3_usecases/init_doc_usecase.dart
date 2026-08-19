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
  ///
  /// ファイル単位で「既にあれば触らない」を守るため、`utakata.yaml` が
  /// 無いのに `plan.yaml` だけある(またはその逆の)半端な状態でも、
  /// 欠けているものだけが補われる。
  Future<bool> execute(String projectDir) async {
    final utakataYamlPath = '$projectDir/utakata.yaml';
    final alreadyInitialized = _fileExists(utakataYamlPath);

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

    await _writeIfAbsent(utakataYamlPath, _defaultUtakataYaml());
    await _writeIfAbsent('$projectDir/doc/summary.md', _defaultSummaryMd());
    // plan.yaml が無いと直後の check / apply が失敗するため、雛形を必ず置く。
    await _writeIfAbsent('$projectDir/doc/specs/plan.yaml', _defaultPlanYaml());

    return !alreadyInitialized;
  }

  Future<void> _writeIfAbsent(String path, String content) async {
    if (_fileExists(path)) return;
    await _writeFile(path, content);
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

# .claude/skills/ に同期するアーキテクチャ同梱 SKILL の有効リスト(utakata skills sync)
# ※ create が生成する汎用スキル(utakata-structure 等)はここに書かない
# skills:
#   - clean-arch-auditor

# 登場人物と役割(AI が「誰の決定に従い、誰に判断を仰ぐか」を把握するための定義)
# team:
#   client: "お客様の名前(要件の決定権者。仕様変更はこの人の合意が必要)"
#   developer: "開発者の名前(アーキテクチャの責任者。コードの最終レビューを行う)"
#   ai_agents:
#     - id: feature-builder
#       role: "実装担当。plan.yaml と層ごとのガイドを読み込みコードを生成する。"

enforcement:
  # on にすると、実装計画の無い feature のスキャフォールドを止める
  # (utakata doc show impl を参照)
  impl_plan: "off"
records:
  git: commit
lang: ja
''';

  String _defaultSummaryMd() => '''
# 案件整理サマリー

<!-- utakata:begin agreements -->
<!-- utakata:end -->
''';

  String _defaultPlanYaml() => '''
# 意図レベルの計画 — 「何を作りたいか」だけを宣言する。
# 具象的なディレクトリ構造は utakata が arch_definition.yaml から毎回導出するため、
# ここには書かない。
#
# 生成: utakata apply --scope feature
# 検証: utakata check
# 既存コードの取り込み: utakata plan adopt
schema: 1

# アーキテクチャは utakata.yaml の project.architecture が優先される。
# feature 単位で上書きしたい場合のみ、各 feature に architecture: を書く。

features: []
# features:
#   - name: todo
#     permission: user        # admin | user | shared | direct
#     entities: [todo]
#
#     # 層ごとの明示宣言(任意)。書かなければ entities から自動導出される。
#     # `utakata plan expand` で現在の自動導出を書き出してから編集するのが楽。
#     layers:
#       1_domain/3_usecases: [get_todo, save_todo]   # 必要なものだけを列挙
#       2_infrastructure/2_data_sources/2_remote: [] # 空リスト = この層は不要
''';
}
