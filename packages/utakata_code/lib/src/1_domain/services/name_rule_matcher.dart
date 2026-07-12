import '../1_entities/architecture_definition_entity.dart';

/// ディレクトリパスに適用される命名規則を解決する純関数サービス。
///
/// 旧実装は `dirPattern.contains(dirPath)` という**部分文字列一致**だったため、
/// 例えば `2_infrastructure/2_data_sources/1_local` ルールが
/// `.../1_local/exceptions` という異なるサブディレクトリにも
/// 誤って適用されてしまっていた(exceptions/ 配下は validate_usecase 側で
/// 丸ごとスキップして回避していたが、その結果 `1_domain/exceptions` に
/// 定義されていた専用ルールも一切適用されなくなっていた)。
///
/// ここでは **パスセグメント単位の末尾一致** に変更する:
/// dirPath のセグメント列が dirPattern のセグメント列で終わっている場合のみ
/// マッチとみなす。これにより、より深い専用ルール(`.../1_local/exceptions`)と
/// その親ルール(`.../1_local`)が誤って混同されなくなる。
abstract final class NameRuleMatcher {
  /// [dirPath] に適用すべきルールを1件返す(なければ null)。
  /// 複数マッチした場合はセグメント数が最も多い(=最も具体的な)ものを採用する。
  static NamingRuleEntity? findFor(
    String dirPath,
    List<NamingRuleEntity> rules,
  ) {
    final pathSegments = _segments(dirPath);
    NamingRuleEntity? best;
    var bestLength = -1;

    for (final rule in rules) {
      final ruleSegments = _segments(rule.dirPattern);
      if (_endsWith(pathSegments, ruleSegments) &&
          ruleSegments.length > bestLength) {
        best = rule;
        bestLength = ruleSegments.length;
      }
    }
    return best;
  }

  static List<String> _segments(String path) =>
      path.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();

  static bool _endsWith(List<String> path, List<String> pattern) {
    if (pattern.length > path.length) return false;
    final offset = path.length - pattern.length;
    for (var i = 0; i < pattern.length; i++) {
      if (path[offset + i] != pattern[i]) return false;
    }
    return true;
  }
}
