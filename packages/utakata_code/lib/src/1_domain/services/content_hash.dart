/// managed マーカー用のコンテンツハッシュ(FNV-1a 64bit)。
///
/// セキュリティ目的ではなく「人間が managed ファイルを編集したか」の
/// 判定のみが目的(実装計画 D4)。
final class ContentHash {
  static String fnv1a(String content) {
    var hash = 0xcbf29ce484222325;
    for (final unit in content.codeUnits) {
      hash ^= unit & 0xFF;
      hash *= 0x100000001b3; // 64bit で自然に wrap する
      hash ^= unit >> 8;
      hash *= 0x100000001b3;
    }
    // Dart の int は符号付き 64bit のため、負値でも '-' の出ない
    // 16 桁 hex に整形する(マーカー正規表現 [0-9a-f]+ と互換)。
    final hi = (hash >> 32) & 0xFFFFFFFF;
    final lo = hash & 0xFFFFFFFF;
    return hi.toRadixString(16).padLeft(8, '0') +
        lo.toRadixString(16).padLeft(8, '0');
  }
}
