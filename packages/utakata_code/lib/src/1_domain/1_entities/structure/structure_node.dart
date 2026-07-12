/// スキャンで得られた実際のファイルシステムノード。
///
/// ディレクトリ / ファイルを sealed class で表現し、ファイルは
/// [FileKind] で「検証対象かどうか」を1箇所で決定する
/// (`*.g.dart` / `*.freezed.dart` を command 単位で個別に除外していた
/// 従来の重複判定を解消する)。
sealed class StructureNode {
  const StructureNode();
}

final class StructureDirNode extends StructureNode {
  /// 子要素(ディレクトリ名/ファイル名 → ノード)
  final Map<String, StructureNode> children;

  const StructureDirNode(this.children);

  static const empty = StructureDirNode({});

  List<String> get fileNames => children.entries
      .where((e) => e.value is StructureFileNode)
      .map((e) => e.key)
      .toList()
    ..sort();

  List<String> get dirNames => children.entries
      .where((e) => e.value is StructureDirNode)
      .map((e) => e.key)
      .toList()
    ..sort();
}

enum FileKind {
  /// 人間/AI が書く実装ファイル。命名検証・差分の対象
  source,

  /// `*.g.dart` / `*.freezed.dart` 等のコード生成ファイル。検証対象外
  generated,
}

final class StructureFileNode extends StructureNode {
  final FileKind kind;

  const StructureFileNode(this.kind);

  bool get isGenerated => kind == FileKind.generated;

  /// ファイル名からコード生成物かどうかを判定する(1箇所に集約)
  static FileKind kindOf(String fileName) {
    if (fileName.endsWith('.g.dart') ||
        fileName.endsWith('.freezed.dart') ||
        fileName.endsWith('.template.dart')) {
      return FileKind.generated;
    }
    return FileKind.source;
  }
}
