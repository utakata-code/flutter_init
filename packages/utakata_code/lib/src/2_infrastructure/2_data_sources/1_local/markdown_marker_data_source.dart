/// `<!-- utakata:begin X --> ... <!-- utakata:end -->` 区間のみを置換する
/// データソース。手書き部分と自動生成区間を1ファイル内で共存させる
/// (案件整理サマリーのマーカー生成。仕様書 §7.3)。
class MarkdownMarkerDataSource {
  const MarkdownMarkerDataSource();

  /// [markerName] の区間を [newContent] に差し替える。マーカーが
  /// 存在しない場合は末尾に新規追加する。
  String replaceSection(String document, String markerName, String newContent) {
    final begin = '<!-- utakata:begin $markerName -->';
    const end = '<!-- utakata:end -->';

    final beginIndex = document.indexOf(begin);
    if (beginIndex == -1) {
      final trimmed = document.trimRight();
      return '$trimmed\n\n$begin\n$newContent\n$end\n';
    }

    final endIndex = document.indexOf(end, beginIndex);
    if (endIndex == -1) {
      // 開始タグのみで終了タグがない場合は壊れているとみなし、そこで打ち切って追記
      final before = document.substring(0, beginIndex);
      return '$before$begin\n$newContent\n$end\n';
    }

    final before = document.substring(0, beginIndex);
    final after = document.substring(endIndex + end.length);
    return '$before$begin\n$newContent\n$end$after';
  }
}
