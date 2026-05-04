/// アーキテクチャ差分エンティティ
///
/// utakata diff コマンドの結果（計画 vs 実績の差分）を表す。
class ArchitectureDiffEntity {
  /// 計画にあるが実績に存在しないパスのリスト（未実装）
  final List<String> missingPaths;

  /// 実績にあるが計画に存在しないパスのリスト（計画外）
  final List<String> extraPaths;

  const ArchitectureDiffEntity({
    required this.missingPaths,
    required this.extraPaths,
  });

  /// 差分なし（計画と実績が完全一致）
  bool get isClean => missingPaths.isEmpty && extraPaths.isEmpty;

  /// 不足しているパスの件数
  int get missingCount => missingPaths.length;

  /// 計画外のパスの件数
  int get extraCount => extraPaths.length;

  @override
  String toString() =>
      'ArchitectureDiffEntity(missing: $missingCount, extra: $extraCount)';
}
