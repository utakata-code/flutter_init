import '../1_entities/architecture_definition_entity.dart';

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
}
