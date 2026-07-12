/// `utakata check` の結果。
///
/// 旧 `ArchitectureDiffEntity`(diff)と `ValidationResultEntity`(validate)を
/// 1回の走査・1つの型に統合する(diff/validate が別々に2回スキャンし、
/// `direct` パーミッションの補償展開が片方にしかない、という
/// 相互補償バグのクラスを構造的に解消する)。
final class NamingViolation {
  /// lib/ からの相対パス
  final String filePath;

  /// 期待されるパターンの説明(例: "{name}_entity.dart")
  final String expectedPattern;

  const NamingViolation({required this.filePath, required this.expectedPattern});

  @override
  String toString() => '$filePath (expected: $expectedPattern)';

  @override
  bool operator ==(Object other) =>
      other is NamingViolation &&
      other.filePath == filePath &&
      other.expectedPattern == expectedPattern;

  @override
  int get hashCode => Object.hash(filePath, expectedPattern);
}

final class CheckReport {
  /// plan にあるが実体にないパス(lib/ からの相対パス、ディレクトリ or ファイル)
  final List<String> missingPaths;

  /// 実体にあるが plan にないパス(かつ allowRules にも合致しない)
  final List<String> extraPaths;

  /// 命名規則違反
  final List<NamingViolation> namingViolations;

  const CheckReport({
    this.missingPaths = const [],
    this.extraPaths = const [],
    this.namingViolations = const [],
  });

  bool get isClean =>
      missingPaths.isEmpty && extraPaths.isEmpty && namingViolations.isEmpty;

  int get violationCount =>
      missingPaths.length + extraPaths.length + namingViolations.length;
}
