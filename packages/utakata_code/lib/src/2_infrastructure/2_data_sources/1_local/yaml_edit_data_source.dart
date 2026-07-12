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
