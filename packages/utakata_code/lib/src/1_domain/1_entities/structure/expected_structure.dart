import '../architecture_definition_entity.dart';

/// plan.yaml(意図レベル)から導出される「あるべきディレクトリ構造」。
///
/// 具象ツリー(旧 plan_architecture.yaml)を永続化する代わりに、
/// [ExpectedStructureBuilder](services/expected_structure_builder.dart)が
/// 毎回この値オブジェクトを純関数で導出する(P1/P3)。
final class ExpectedDir {
  final String name;
  final Map<String, ExpectedDir> children;

  /// 命名が決定的な場合にのみ列挙されるファイル名(例: `{name}_entity.dart`)。
  /// 決定的でない場合(usecases 等)は空 — その場合はこのディレクトリの
  /// [allowRule] に合致する任意のファイルが正当とみなされる(allowRules方式)。
  final Set<String> requiredFiles;

  /// このディレクトリに適用される命名規則(最深一致で1件、無ければ null)
  final NamingRuleEntity? allowRule;

  /// ディレクトリ自体の存在が必須か(Issue #12)。
  ///
  /// plan.yaml の `layers` でその層が空リスト宣言(= 不要)された場合に false。
  /// false のディレクトリは、存在しなくても missing として報告しない。
  /// 存在する場合は通常どおり中身の命名を検証する(寛容側に倒す)。
  final bool required;

  const ExpectedDir({
    required this.name,
    this.children = const {},
    this.requiredFiles = const {},
    this.allowRule,
    this.required = true,
  });

  ExpectedDir copyWith({
    Map<String, ExpectedDir>? children,
    Set<String>? requiredFiles,
    NamingRuleEntity? allowRule,
    bool? required,
  }) =>
      ExpectedDir(
        name: name,
        children: children ?? this.children,
        requiredFiles: requiredFiles ?? this.requiredFiles,
        allowRule: allowRule ?? this.allowRule,
        required: required ?? this.required,
      );
}

final class ExpectedStructure {
  /// トップレベルの子(permission 名、または direct feature 名)
  final Map<String, ExpectedDir> topLevel;

  const ExpectedStructure(this.topLevel);

  static const empty = ExpectedStructure({});
}
