/// バリデーション結果エンティティ
///
/// `utakata validate` コマンドの実行結果を格納する。
/// 命名違反とディレクトリ構造違反の両方を保持する。
class ValidationResultEntity {
  /// 命名規則違反リスト
  final List<NamingViolationEntity> namingViolations;

  /// ディレクトリ構造の Missing（計画にあるが未実装）
  final List<String> missingDirs;

  /// ディレクトリ構造の Extra（実績にあるが計画外）
  final List<String> extraDirs;

  const ValidationResultEntity({
    required this.namingViolations,
    required this.missingDirs,
    required this.extraDirs,
  });

  /// 全て問題なし
  bool get isClean =>
      namingViolations.isEmpty && missingDirs.isEmpty && extraDirs.isEmpty;

  int get namingViolationCount => namingViolations.length;
  int get missingDirCount => missingDirs.length;
  int get extraDirCount => extraDirs.length;
}

/// 命名規則違反エンティティ
class NamingViolationEntity {
  /// 違反ファイルの相対パス（features/ 以降）
  final String filePath;

  /// 期待されるパターンの説明（例: "{name}_entity.dart"）
  final String expectedPattern;

  const NamingViolationEntity({
    required this.filePath,
    required this.expectedPattern,
  });
}
