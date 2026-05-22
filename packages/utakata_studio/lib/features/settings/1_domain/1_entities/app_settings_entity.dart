import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_entity.freezed.dart';

/// アプリ設定エンティティ
///
/// utakata CLI のパスやプロジェクトルート等の設定を保持する。
@freezed
abstract class AppSettingsEntity with _$AppSettingsEntity {
  const factory AppSettingsEntity({
    @Default('utakata') String utakataCliPath,
    String? projectRoot,
  }) = _AppSettingsEntity;
}
