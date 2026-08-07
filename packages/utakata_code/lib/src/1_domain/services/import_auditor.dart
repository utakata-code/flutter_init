import '../1_entities/architecture_definition_entity.dart';
import '../1_entities/imports/import_audit_report.dart';

/// import の健全性を決定論的に監査する純関数サービス(Issue #20)。
///
/// - **内部依存**(プロジェクト内 import): [InternalImportRule] のホワイトリスト。
///   自層への import は常に許可。どの層にも属さないパス(`core/`、`main.dart`、
///   DI を束ねる composition root 等)への import は監査対象外 —
///   これが「例外パターン」の受け皿になる。
/// - **外部依存**(`package:` / `dart:` import): [ExternalImportRule] の
///   ブラックリスト。該当する全ルールの deny を重ねて適用する。
///
/// パターン照合はすべて**パスセグメント単位**([NameRuleMatcher] と同じ流儀。
/// ただし途中一致も許す): `1_domain` は
/// `lib/features/user/todo/1_domain/1_entities` に一致する。
abstract final class ImportAuditor {
  /// [selfPackage]: 監査対象プロジェクトのパッケージ名(pubspec.yaml の name)。
  ///   `package:<selfPackage>/...` は内部依存として解決される。
  /// [knownScopes]: 「層に属する」と判定するためのパス集合(層名 + 全 dirPattern)。
  ///   内部 import の宛先がこのどれにも属さなければ監査対象外とする。
  static ImportAuditReport audit({
    required ImportRuleSet rules,
    required String selfPackage,
    required Iterable<DartSourceFile> files,
    required Set<String> knownScopes,
  }) {
    final excludeRegexps =
        rules.excludePatterns.map(_globToRegExp).toList(growable: false);
    final scopeSegments =
        knownScopes.map(_segments).where((s) => s.isNotEmpty).toList();

    final violations = <ImportViolation>[];
    var audited = 0;
    var excluded = 0;

    for (final file in files) {
      if (excludeRegexps.any((r) => r.hasMatch(file.path))) {
        excluded++;
        continue;
      }
      audited++;

      final dirSegments = _segments(_dirname(file.path));
      final internalRule = _findInternalRule(dirSegments, rules.internalRules);
      final externalRules = rules.externalRules
          .where((r) => _containsRun(dirSegments, _segments(r.dirPattern)))
          .toList(growable: false);

      for (final uri in file.imports) {
        if (uri.startsWith('dart:')) {
          final denied = _findDeny(externalRules, uri);
          if (denied != null) {
            violations.add(ImportViolation(
              filePath: file.path,
              importUri: uri,
              kind: ImportViolationKind.external,
              detail: '「${denied.$1.dirPattern}」では '
                  '$uri の import が禁止されています(deny: ${denied.$2})',
            ));
          }
          continue;
        }

        if (uri.startsWith('package:')) {
          final rest = uri.substring('package:'.length);
          final slash = rest.indexOf('/');
          final pkg = slash < 0 ? rest : rest.substring(0, slash);

          if (pkg == selfPackage && slash >= 0) {
            _checkInternal(file, uri, 'lib/${rest.substring(slash + 1)}',
                internalRule, scopeSegments, violations);
          } else {
            final denied = _findDeny(externalRules, pkg);
            if (denied != null) {
              violations.add(ImportViolation(
                filePath: file.path,
                importUri: uri,
                kind: ImportViolationKind.external,
                detail: '「${denied.$1.dirPattern}」では '
                    'package:$pkg の import が禁止されています(deny: ${denied.$2})',
              ));
            }
          }
          continue;
        }

        // スキーム無し = 相対 import(プロジェクト内)
        if (!uri.contains(':')) {
          final target = _normalize('${_dirname(file.path)}/$uri');
          _checkInternal(
              file, uri, target, internalRule, scopeSegments, violations);
        }
      }
    }

    violations.sort((a, b) {
      final byFile = a.filePath.compareTo(b.filePath);
      return byFile != 0 ? byFile : a.importUri.compareTo(b.importUri);
    });

    return ImportAuditReport(
      violations: violations,
      auditedFileCount: audited,
      excludedFileCount: excluded,
    );
  }

  /// 内部 import の宛先 [target](プロジェクト相対パス)を検証する。
  static void _checkInternal(
    DartSourceFile file,
    String uri,
    String target,
    InternalImportRule? rule,
    List<List<String>> scopeSegments,
    List<ImportViolation> violations,
  ) {
    if (rule == null) return; // 発信元が層に属さない → 監査対象外

    final targetDir = _segments(_dirname(target));

    // 自層への import は常に許可
    if (_containsRun(targetDir, _segments(rule.dirPattern))) return;

    // ホワイトリスト照合
    for (final allow in rule.allow) {
      if (_containsRun(targetDir, _segments(allow))) return;
    }

    // 宛先がどの層にも属さない(core/ 等) → 監査対象外
    final targetScope = _longestScope(targetDir, scopeSegments);
    if (targetScope == null) return;

    violations.add(ImportViolation(
      filePath: file.path,
      importUri: uri,
      kind: ImportViolationKind.internal,
      detail: '「${rule.dirPattern}」から「$targetScope」への import は'
          '許可されていません(allow: ${rule.allow.isEmpty ? "なし" : rule.allow.join(", ")})',
    ));
  }

  /// [dirSegments] に最も具体的に(セグメント数最長で)一致する内部ルールを返す。
  static InternalImportRule? _findInternalRule(
    List<String> dirSegments,
    List<InternalImportRule> rules,
  ) {
    InternalImportRule? best;
    var bestLength = -1;
    for (final rule in rules) {
      final pattern = _segments(rule.dirPattern);
      if (_containsRun(dirSegments, pattern) && pattern.length > bestLength) {
        best = rule;
        bestLength = pattern.length;
      }
    }
    return best;
  }

  /// [pkgName] を禁止している (ルール, deny エントリ) を返す。なければ null。
  static (ExternalImportRule, String)? _findDeny(
    List<ExternalImportRule> rules,
    String pkgName,
  ) {
    for (final rule in rules) {
      for (final deny in rule.deny) {
        if (_globToRegExp(deny).hasMatch(pkgName)) return (rule, deny);
      }
    }
    return null;
  }

  /// [targetDir] が属する最も具体的なスコープ(表示用)。属さなければ null。
  static String? _longestScope(
    List<String> targetDir,
    List<List<String>> scopeSegments,
  ) {
    List<String>? best;
    for (final scope in scopeSegments) {
      if (_containsRun(targetDir, scope) &&
          scope.length > (best?.length ?? 0)) {
        best = scope;
      }
    }
    return best?.join('/');
  }

  // ─── パス・パターンユーティリティ(POSIX 前提の純関数) ───

  static List<String> _segments(String path) =>
      path.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();

  /// [pattern] のセグメント列が [path] のどこかに連続して現れるか。
  static bool _containsRun(List<String> path, List<String> pattern) {
    if (pattern.isEmpty || pattern.length > path.length) return false;
    for (var start = 0; start <= path.length - pattern.length; start++) {
      var matched = true;
      for (var i = 0; i < pattern.length; i++) {
        if (path[start + i] != pattern[i]) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  static String _dirname(String path) {
    final index = path.lastIndexOf('/');
    return index < 0 ? '' : path.substring(0, index);
  }

  /// `..` / `.` を解決した正規化(POSIX)。ルートより上へは出ない。
  static String _normalize(String path) {
    final out = <String>[];
    for (final segment in path.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (out.isNotEmpty) out.removeLast();
        continue;
      }
      out.add(segment);
    }
    return out.join('/');
  }

  /// glob(`*` = `/` 以外の任意列、`**` = 任意列)を正規表現へ変換する。
  static RegExp _globToRegExp(String glob) {
    final buffer = StringBuffer('^');
    for (var i = 0; i < glob.length; i++) {
      final char = glob[i];
      if (char == '*') {
        if (i + 1 < glob.length && glob[i + 1] == '*') {
          buffer.write('.*');
          i++;
        } else {
          buffer.write('[^/]*');
        }
      } else if (r'\^$.|?+()[]{}'.contains(char)) {
        buffer.write('\\$char');
      } else {
        buffer.write(char);
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }
}
