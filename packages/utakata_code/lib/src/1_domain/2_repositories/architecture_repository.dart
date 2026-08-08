import '../1_entities/architecture_definition_entity.dart';
import '../1_entities/dependency_stack_entity.dart';

/// アーキテクチャ定義を取得するリポジトリのインターフェース
///
/// 実装は 2_infrastructure/3_repositories/architecture_repository_impl.dart に存在する。
/// arch_definition.yaml を読み込んで ArchitectureDefinitionEntity を返す。
abstract interface class ArchitectureRepository {
  /// 指定した ID のアーキテクチャ定義を取得する
  ///
  /// [architectureId]: 'clean_architecture', 'mvvm' 等
  /// 該当する定義が存在しない場合は [ArchitectureNotFoundException] をスロー
  Future<ArchitectureDefinitionEntity> getById(String architectureId);

  /// 利用可能なアーキテクチャ定義の一覧を取得する
  Future<List<ArchitectureDefinitionEntity>> getAll();

  /// 指定した ID のアーキテクチャ定義の生 YAML テキストを取得する
  ///
  /// ローカル優先読み込みルールを適用する。
  /// 該当する定義が存在しない場合は [ArchitectureNotFoundException] をスロー。
  Future<String> getRawDefinition(String architectureId);

  /// 外部依存スタック(`dependencies/*.yaml`)を取得する(v1.5.0)。
  ///
  /// `core_stack.yaml` は pubspec 生成(`utakata create`)+ 配置宣言、
  /// その他の `*.yaml`(recommended 等)は配置宣言のみに使われる。
  /// `dependencies/` が無い旧構成では、arch_definition.yaml 内の
  /// `dependencies:`/`dev_dependencies:`(v1 書式)へフォールバックする
  /// (その場合、配置宣言は空)。
  Future<DependencyStack> getDependencyStack(String architectureId);
}
