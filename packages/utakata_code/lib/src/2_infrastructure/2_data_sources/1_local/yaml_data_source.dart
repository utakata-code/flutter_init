import 'package:yaml/yaml.dart';

/// YAML 読み書きを担うデータソース
class YamlDataSource {
  const YamlDataSource();

  /// YAML 文字列を Map に変換する。解析失敗時は null を返す
  Map<String, dynamic>? parse(String yamlStr) {
    try {
      final doc = loadYaml(yamlStr);
      if (doc == null) return null;
      return _yamlToMap(doc);
    } catch (_) {
      return null;
    }
  }

  /// Map を YAML 文字列にシリアライズする
  String serialize(Map<String, dynamic> data, {int indent = 0}) {
    final buf = StringBuffer();
    _writeMap(data, buf, indent);
    return buf.toString();
  }

  // ------ private ------

  /// YamlMap / YamlList → Dart Map/List に再帰変換する
  Map<String, dynamic> _yamlToMap(dynamic node) {
    if (node is YamlMap) {
      final result = <String, dynamic>{};
      for (final entry in node.entries) {
        final key = entry.key as String;
        final value = entry.value;
        result[key] = _yamlToValue(value);
      }
      return result;
    }
    return {};
  }

  dynamic _yamlToValue(dynamic value) {
    if (value is YamlMap) return _yamlToMap(value);
    if (value is YamlList) return value.map(_yamlToValue).toList();
    return value;
  }

  void _writeMap(Map<String, dynamic> map, StringBuffer buf, int indent) {
    final pad = '  ' * indent;
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        buf.writeln('$pad$key:');
        _writeMap(value, buf, indent + 1);
      } else if (value is List) {
        buf.writeln('$pad$key:');
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            buf.writeln('$pad  -');
            _writeMap(item, buf, indent + 2);
          } else {
            buf.writeln('$pad  - $item');
          }
        }
      } else if (value == null || (value is Map && value.isEmpty)) {
        buf.writeln('$pad$key: {}');
      } else {
        buf.writeln('$pad$key: $value');
      }
    }
  }
}
