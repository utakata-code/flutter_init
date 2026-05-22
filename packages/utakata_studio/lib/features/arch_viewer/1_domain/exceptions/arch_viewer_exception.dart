/// アーキテクチャビューア関連の例外
class ArchViewerException implements Exception {
  final String message;
  const ArchViewerException(this.message);

  @override
  String toString() => 'ArchViewerException: $message';
}
