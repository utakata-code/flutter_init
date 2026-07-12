/// lib/ 相対パスの正規化表現。
///
/// Windows のバックスラッシュ・POSIX のスラッシュ双方を受け付け、
/// 常に `/` 区切りのセグメント列として保持する。パス正規化・
/// `direct` パーミッションの展開規約は、この型とその利用箇所
/// (StructureChecker / ExpectedStructureBuilder)にのみ集約する。
final class StructurePath {
  final List<String> segments;

  StructurePath(List<String> segments) : segments = List.unmodifiable(segments);

  factory StructurePath.parse(String raw) {
    final normalized = raw.replaceAll('\\', '/');
    final parts = normalized.split('/').where((s) => s.isNotEmpty).toList();
    return StructurePath(parts);
  }

  static final StructurePath root = StructurePath(const []);

  StructurePath child(String segment) => StructurePath([...segments, segment]);

  bool get isRoot => segments.isEmpty;

  String get value => segments.join('/');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    if (other is! StructurePath) return false;
    if (other.segments.length != segments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(segments);
}
