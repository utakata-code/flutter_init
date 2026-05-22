import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/2_repositories/settings_repository.dart';
import '../../1_domain/3_usecases/load_settings_usecase.dart';
import '../../1_domain/3_usecases/save_settings_usecase.dart';
import '../../2_infrastructure/2_data_sources/1_local/settings_local_data_source.dart';
import '../../2_infrastructure/3_repositories/settings_repository_impl.dart';

/// 設定の DI プロバイダ

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSource(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.read(settingsLocalDataSourceProvider)),
);

final loadSettingsUsecaseProvider = Provider<LoadSettingsUsecase>(
  (ref) => LoadSettingsUsecase(ref.read(settingsRepositoryProvider)),
);

final saveSettingsUsecaseProvider = Provider<SaveSettingsUsecase>(
  (ref) => SaveSettingsUsecase(ref.read(settingsRepositoryProvider)),
);
