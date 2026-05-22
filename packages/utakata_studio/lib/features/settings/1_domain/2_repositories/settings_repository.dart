import '../1_entities/app_settings_entity.dart';

/// 設定リポジトリの抽象インターフェース
///
/// 設定の永続化と読み込みを抽象化する。
abstract interface class SettingsRepository {
  /// 設定を読み込む
  ///
  /// Returns: 保存済みの設定。未保存の場合はデフォルト値
  Future<AppSettingsEntity> load();

  /// 設定を保存する
  ///
  /// [settings] 保存する設定
  Future<void> save(AppSettingsEntity settings);
}
