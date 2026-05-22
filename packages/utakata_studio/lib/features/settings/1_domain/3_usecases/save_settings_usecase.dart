import '../1_entities/app_settings_entity.dart';
import '../2_repositories/settings_repository.dart';

/// 設定を保存するユースケース
class SaveSettingsUsecase {
  final SettingsRepository _repository;
  const SaveSettingsUsecase(this._repository);

  /// 設定を永続化する
  ///
  /// [settings] 保存する設定
  Future<void> call(AppSettingsEntity settings) => _repository.save(settings);
}
