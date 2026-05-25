import '../1_entities/app_settings_entity.dart';
import '../2_repositories/settings_repository.dart';

/// 設定をロードするユースケース
class LoadSettingsUsecase {
  final SettingsRepository _repository;
  const LoadSettingsUsecase(this._repository);

  /// 設定を読み込んで返す
  Future<AppSettingsEntity> call() => _repository.load();
}
