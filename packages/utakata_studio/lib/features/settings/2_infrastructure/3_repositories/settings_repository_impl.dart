import '../../1_domain/1_entities/app_settings_entity.dart';
import '../../1_domain/2_repositories/settings_repository.dart';
import '../1_models/app_settings_model.dart';
import '../2_data_sources/1_local/settings_local_data_source.dart';

/// 設定リポジトリの実装
///
/// データソースから Model を取得し、Entity に変換して返す。
/// Entity → Model の変換もここで行う。
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;
  const SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<AppSettingsEntity> load() async {
    final model = await _localDataSource.load();
    return model.toEntity();
  }

  @override
  Future<void> save(AppSettingsEntity settings) async {
    final model = AppSettingsModel.fromEntity(settings);
    await _localDataSource.save(model);
  }
}
