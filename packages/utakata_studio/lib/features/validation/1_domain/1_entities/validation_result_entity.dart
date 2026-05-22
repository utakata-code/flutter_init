import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:utakata/utakata.dart';

part 'validation_result_entity.freezed.dart';

/// YAML バリデーション結果エンティティ
@freezed
abstract class ValidationResultEntity with _$ValidationResultEntity {
  const ValidationResultEntity._();

  const factory ValidationResultEntity({
    required String yamlContent,
    required bool isValid,
    String? errorMessage,
    @Default([]) List<LayerDefinitionEntity> layers,
    @Default([]) List<NamingRuleEntity> namingRules,
    @Default([]) List<CoreModuleEntity> coreModules,
    @Default([]) List<GuideEntity> guides,
  }) = _ValidationResultEntity;

  /// 全レイヤーのディレクトリ合計数
  int get totalDirs => layers.fold<int>(0, (sum, l) => sum + l.dirs.length);
}
