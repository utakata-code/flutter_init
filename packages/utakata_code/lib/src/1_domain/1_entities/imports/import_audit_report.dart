/// `utakata imports`(Issue #20)の入出力エンティティ群。
library;

/// 監査対象の Dart ソースファイル1件。
///
/// [path] はプロジェクトルートからの相対パス(POSIX 区切り。例:
/// `lib/features/user/todo/1_domain/1_entities/todo_entity.dart`)。
/// [imports] は import/export ディレクティブの URI 文字列。
final class DartSourceFile {
  final String path;
  final List<String> imports;

  const DartSourceFile({required this.path, required this.imports});
}

enum ImportViolationKind {
  /// 内部依存: ホワイトリストにない層への import
  internal,

  /// 外部依存: ブラックリストにあるパッケージの import
  external,
}

/// import 違反1件。
final class ImportViolation {
  /// 違反したファイル(プロジェクト相対パス)
  final String filePath;

  /// 違反した import の URI(書かれたまま)
  final String importUri;

  final ImportViolationKind kind;

  /// 人間向けの違反理由(どの規則に反したか)
  final String detail;

  const ImportViolation({
    required this.filePath,
    required this.importUri,
    required this.kind,
    required this.detail,
  });
}

/// 監査結果。
final class ImportAuditReport {
  final List<ImportViolation> violations;

  /// 監査した(exclude されなかった)ファイル数
  final int auditedFileCount;

  /// exclude glob で除外したファイル数
  final int excludedFileCount;

  const ImportAuditReport({
    required this.violations,
    required this.auditedFileCount,
    required this.excludedFileCount,
  });

  bool get isClean => violations.isEmpty;
}
