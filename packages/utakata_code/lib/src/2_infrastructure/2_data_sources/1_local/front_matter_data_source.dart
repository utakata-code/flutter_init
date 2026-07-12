import 'package:yaml/yaml.dart';

import 'yaml_data_source.dart';

/// `--- ... ---` 区切りの frontmatter + 本文の読み書きを担うデータソース。
///
/// 本文バイト列は不変更のまま扱う(実装計画書の自由記述部分を壊さない)。
class FrontMatterDataSource {
  final YamlDataSource _yaml;

  const FrontMatterDataSource(this._yaml);

  static final _pattern = RegExp(r'^---\r?\n(.*?)\r?\n---\r?\n?', dotAll: true);

  /// frontmatter を Map として、本文をそのまま返す。frontmatter が無ければ
  /// 空 Map + 全文を本文として返す。
  ({Map<String, dynamic> frontMatter, String body}) parse(String content) {
    final match = _pattern.firstMatch(content);
    if (match == null) {
      return (frontMatter: <String, dynamic>{}, body: content);
    }
    final yamlBlock = match.group(1)!;
    final frontMatter = _yaml.parse(yamlBlock, source: '<frontmatter>');
    final body = content.substring(match.end);
    return (frontMatter: frontMatter, body: body);
  }

  /// frontmatter を書き換え、本文はそのまま連結して返す。
  String render(Map<String, dynamic> frontMatter, String body) {
    final buffer = StringBuffer('---\n');
    _writeYaml(frontMatter, buffer, 0);
    buffer.write('---\n');
    buffer.write(body);
    return buffer.toString();
  }

  void _writeYaml(Map<String, dynamic> map, StringBuffer buf, int indent) {
    final pad = '  ' * indent;
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        buf.writeln('$pad$key:');
        _writeYaml(value, buf, indent + 1);
      } else if (value is List) {
        if (value.isEmpty) {
          buf.writeln('$pad$key: []');
        } else {
          buf.writeln('$pad$key:');
          for (final item in value) {
            buf.writeln('$pad  - $item');
          }
        }
      } else if (value is YamlMap || value is YamlList) {
        buf.writeln('$pad$key: $value');
      } else if (value == null) {
        buf.writeln('$pad$key: null');
      } else if (value is String) {
        buf.writeln('$pad$key: "${value.replaceAll('"', '\\"')}"');
      } else {
        buf.writeln('$pad$key: $value');
      }
    }
  }
}
