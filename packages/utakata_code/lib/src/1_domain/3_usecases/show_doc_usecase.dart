/// 同梱ドキュメント(`doc/*.md`)の閲覧。
///
/// 設定ファイルの書き方は CLI の仕様そのものなので、アーキテクチャナレッジ
/// (`guide` 系)とは別系統として、インストール済みバージョンに対応した内容を
/// プロジェクト内から引けるようにする。AI エージェントが
/// 「plan.yaml の書き方」を正確に知るための経路でもある。
class ShowDocUsecase {
  /// トピック ID → 同梱ファイルパス(パッケージルートからの相対)
  static const topics = <String, String>{
    'config': 'doc/utakata-yaml.md',
    'plan': 'doc/plan-yaml.md',
    'imports': 'doc/import-rules.md',
    'records': 'doc/records.md',
    'impl': 'doc/impl-plan.md',
    'index': 'doc/README.md',
  };

  /// トピック ID → 一覧表示用の説明
  static const descriptions = <String, String>{
    'config': 'utakata.yaml — プロジェクト全体のマスター設定',
    'plan': 'doc/specs/plan.yaml — feature の意図レベル計画',
    'imports': 'import_rules — import 健全性の監査規則(utakata imports)',
    'records': 'doc/records/ — 記録の4系統と AI に許す範囲(records.agent_write)',
    'impl': 'doc/impl/ — 実装計画の2軸ライフサイクルとレーン',
    'index': 'ドキュメント索引',
  };

  final Future<String?> Function(String relativePath) _resolvePackageFilePath;
  final Future<String?> Function(String path) _readFile;

  const ShowDocUsecase({
    required Future<String?> Function(String relativePath) resolvePackageFilePath,
    required Future<String?> Function(String path) readFile,
  })  : _resolvePackageFilePath = resolvePackageFilePath,
        _readFile = readFile;

  /// [topic] の本文を返す。未知のトピック・ファイル欠落時は null。
  Future<String?> execute(String topic) async {
    final relativePath = topics[topic];
    if (relativePath == null) return null;
    final path = await _resolvePackageFilePath(relativePath);
    if (path == null) return null;
    return _readFile(path);
  }
}
