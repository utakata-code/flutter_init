import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// `package:yaml_edit` を用いた YAML の外科的編集を担うデータソース。
///
/// 自作シリアライザ([YamlDataSource.serialize])と異なり、既存ファイルの
/// コメント・書式を保持したまま特定ノードだけを更新できる。機械が
/// 人間の書いた YAML(plan.yaml 等)に書き込む唯一の正規経路とする(P4)。
class YamlEditDataSource {
  const YamlEditDataSource();

  /// 新規 YAML ドキュメントを Map からレンダリングする(新規作成時のみ使用。
  /// 既存ファイルの更新には [appendToList] を使うこと)。
  String render(Map<String, dynamic> data) {
    final editor = YamlEditor('');
    editor.update([], data);
    return editor.toString();
  }

  /// 既存 YAML 文字列の `path` が指すリストへ、コメント・書式を保持したまま
  /// 1件追記する。リストが存在しない場合は新規作成する。
  String appendToList(
    String yamlContent,
    List<Object> path,
    Object value,
  ) {
    final editor = YamlEditor(yamlContent);
    final current = _navigate(editor.parseAt([]), path);
    if (current is YamlList) {
      editor.appendToList(path, value);
    } else {
      editor.update(path, [value]);
    }
    return editor.toString();
  }

  /// `path` が指すノードを value で置き換える(存在しなければ作成する)。
  /// コメント・書式は保持される。
  ///
  /// `yaml_edit` の `update` は中間ノードを自動生成しない(存在しないパスは
  /// 例外)ため、欠けている中間 Map をここで先に作ってから更新する。
  String setAt(String yamlContent, List<Object> path, Object value) {
    final editor = YamlEditor(yamlContent);
    for (var i = 1; i < path.length; i++) {
      final parentPath = path.sublist(0, i);
      if (_navigate(editor.parseAt([]), parentPath) == null) {
        editor.update(parentPath, <String, dynamic>{});
      }
    }
    editor.update(path, value);
    return editor.toString();
  }

  /// `path` が指すノードが存在するか(値が null の場合も false)。
  bool hasNode(String yamlContent, List<Object> path) =>
      _navigate(YamlEditor(yamlContent).parseAt([]), path) != null;

  /// `path` が指すリストから、値が [value] と一致する最初の要素を削除する。
  /// 見つからない場合は元の内容をそのまま返す。
  String removeFromList(String yamlContent, List<Object> path, Object value) {
    final editor = YamlEditor(yamlContent);
    final current = _navigate(editor.parseAt([]), path);
    if (current is! YamlList) return yamlContent;
    for (var i = 0; i < current.length; i++) {
      if (current[i] == value) {
        editor.remove([...path, i]);
        return editor.toString();
      }
    }
    return yamlContent;
  }

  /// `features:` 配列内で `name` が一致する feature のインデックスを返す。
  /// 見つからなければ -1。
  int indexOfFeature(String yamlContent, String featureName) {
    final root = YamlEditor(yamlContent).parseAt([]);
    if (root is! YamlMap) return -1;
    final features = root['features'];
    if (features is! YamlList) return -1;
    for (var i = 0; i < features.length; i++) {
      final f = features[i];
      if (f is YamlMap && f['name'] == featureName) return i;
    }
    return -1;
  }

  dynamic _navigate(dynamic node, List<Object> path) {
    var current = node;
    for (final key in path) {
      if (current is YamlMap && key is String) {
        current = current[key];
      } else if (current is YamlList && key is int) {
        if (key < 0 || key >= current.length) return null;
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
