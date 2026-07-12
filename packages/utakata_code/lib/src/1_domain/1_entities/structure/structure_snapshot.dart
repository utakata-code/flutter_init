import 'structure_node.dart';

/// `lib/features/` を一度スキャンした結果の不変スナップショット。
///
/// 永続化はしない(P1: ファイルシステムが唯一の真実)。毎回その場で
/// スキャンして生成し、破棄可能なキャッシュとしてのみ扱う。
final class StructureSnapshot {
  final StructureDirNode root;
  final DateTime scannedAt;

  const StructureSnapshot({required this.root, required this.scannedAt});

  static StructureSnapshot empty(DateTime scannedAt) =>
      StructureSnapshot(root: StructureDirNode.empty, scannedAt: scannedAt);
}
