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
/// 監査対象は `lib/features/` 配下のみ(層構造が定義されるのはそこだけ。
/// `lib/core/` などに層名と同名のディレクトリがあっても層として誤分類しない)。
/// パターン照合はすべて**パスセグメント単位**([NameRuleMatcher] と同じ流儀。
/// ただし途中一致も許す): `1_domain` は
/// `lib/features/user/todo/1_domain/1_entities` に一致する。
abstract final class ImportAuditor {
  /// 層構造が存在する監査ルート。この外のファイル・宛先は監査対象外。
  static const _auditRootPrefix = 'lib/features/';
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

      // 層構造の外(core/、main.dart 等)のファイルは監査しない
      final inScope = file.path.startsWith(_auditRootPrefix);
      final dirSegments = _segments(_dirname(file.path));
      final internalRule =
          inScope ? _findInternalRule(dirSegments, rules.internalRules) : null;
      final externalRules = !inScope
          ? const <ExternalImportRule>[]
          : rules.externalRules
              .where((r) => _containsRun(dirSegments, _segments(r.dirPattern)))
              .toList(growable: false);

      for (final uri in file.imports) {
        if (uri.startsWith('dart:')) {
          _checkExternal(file, uri, uri, externalRules, violations);
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
            _checkExternal(file, uri, pkg, externalRules, violations);
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

    // 宛先が監査ルートの外(core/ 等) → 監査対象外
    if (!target.startsWith(_auditRootPrefix)) return;

    final targetDir = _segments(_dirname(target));

    // 自層への import は常に許可
    if (_containsRun(targetDir, _segments(rule.dirPattern))) return;

    // ホワイトリスト照合
    for (final allow in rule.allow) {
      if (_containsRun(targetDir, _segments(allow))) return;
    }

    // 宛先がどの層にも属さない → 監査対象外
    final targetScope = _longestScope(targetDir, scopeSegments);
    if (targetScope == null) return;

    violations.add(ImportViolation(
      filePath: file.path,
      importUri: uri,
      kind: ImportViolationKind.internal,
      rulePattern: rule.dirPattern,
      target: targetScope,
      ruleDetail: rule.allow,
    ));
  }

  /// 外部 import([pkgName] = パッケージ名または `dart:` URI)を検証する。
  static void _checkExternal(
    DartSourceFile file,
    String uri,
    String pkgName,
    List<ExternalImportRule> externalRules,
    List<ImportViolation> violations,
  ) {
    final denied = _findDeny(externalRules, pkgName);
    if (denied == null) return;
    violations.add(ImportViolation(
      filePath: file.path,
      importUri: uri,
      kind: ImportViolationKind.external,
      rulePattern: denied.$1.dirPattern,
      target: pkgName,
      ruleDetail: [denied.$2],
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

  /// Dart ソースから import/export ディレクティブの URI を抽出する。
  ///
  /// 正規表現ではなく軽量な字句走査を行う:
  /// - 行コメント・ブロックコメント(ネスト対応)内の import 行は無視する
  /// - 文字列リテラル(`'''` 複数行・raw 含む)内の import 行は無視する
  /// - `import 'a.dart' if (dart.library.io) 'b.dart';` の**全分岐 URI** を返す
  /// - キーワードは行頭(空白のみの後)にある場合のみディレクティブとみなす
  static List<String> extractDirectives(String source) {
    final uris = <String>[];
    var i = 0;
    final n = source.length;
    var lineStart = true; // 行頭から空白・コメントのみか
    var inDirective = false; // import/export 読了後、';' まで

    bool isIdentCode(int c) =>
        (c >= 0x30 && c <= 0x39) || // 0-9
        (c >= 0x41 && c <= 0x5A) || // A-Z
        (c >= 0x61 && c <= 0x7A) || // a-z
        c == 0x5F || // _
        c == 0x24; // $

    while (i < n) {
      final ch = source[i];

      if (ch == '\n') {
        lineStart = true;
        i++;
        continue;
      }
      if (ch == ' ' || ch == '\t' || ch == '\r') {
        i++;
        continue;
      }

      // コメント
      if (ch == '/' && i + 1 < n) {
        final next = source[i + 1];
        if (next == '/') {
          while (i < n && source[i] != '\n') {
            i++;
          }
          continue;
        }
        if (next == '*') {
          var depth = 1;
          i += 2;
          while (i < n && depth > 0) {
            if (source.startsWith('/*', i)) {
              depth++;
              i += 2;
            } else if (source.startsWith('*/', i)) {
              depth--;
              i += 2;
            } else {
              i++;
            }
          }
          continue;
        }
      }

      // 文字列リテラル(raw プレフィックス r'...' / r"..." を含む)
      final isRawString = ch == 'r' &&
          i + 1 < n &&
          (source[i + 1] == "'" || source[i + 1] == '"');
      if (ch == "'" || ch == '"' || isRawString) {
        final quoteIndex = isRawString ? i + 1 : i;
        final quote = source[quoteIndex];
        final triple = source.startsWith(quote * 3, quoteIndex);
        var j = quoteIndex + (triple ? 3 : 1);
        final content = StringBuffer();
        while (j < n) {
          if (!isRawString && source[j] == r'\' && j + 1 < n) {
            content.write(source[j + 1]);
            j += 2;
            continue;
          }
          if (triple ? source.startsWith(quote * 3, j) : source[j] == quote) {
            j += triple ? 3 : 1;
            break;
          }
          content.write(source[j]);
          j++;
        }
        // ディレクティブ内の(単一行)文字列 = URI。条件付き import の
        // 各分岐もここで拾われる。
        if (inDirective && !triple) uris.add(content.toString());
        i = j;
        lineStart = false;
        continue;
      }

      // 識別子・キーワード
      if (isIdentCode(ch.codeUnitAt(0))) {
        final start = i;
        while (i < n && isIdentCode(source.codeUnitAt(i))) {
          i++;
        }
        final word = source.substring(start, i);
        if (lineStart && (word == 'import' || word == 'export')) {
          inDirective = true;
        }
        lineStart = false;
        continue;
      }

      if (ch == ';') inDirective = false;
      lineStart = false;
      i++;
    }
    return uris;
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
