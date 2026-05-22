import 'package:freezed_annotation/freezed_annotation.dart';
import '../../1_domain/1_entities/app_settings_entity.dart';

part 'settings_state.freezed.dart';

/// 設定の状態
@freezed
sealed class SettingsState with _$SettingsState {
  /// 初期状態（ロード前）
  const factory SettingsState.initial() = SettingsStateInitial;

  /// ローディング状態
  const factory SettingsState.loading() = SettingsStateLoading;

  /// データ読み込み完了状態
  const factory SettingsState.loaded({
    required AppSettingsEntity settings,
  }) = SettingsStateLoaded;

  /// エラー状態
  const factory SettingsState.error(String message) = SettingsStateError;
}
