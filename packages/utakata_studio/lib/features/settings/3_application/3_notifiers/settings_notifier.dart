import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/1_entities/app_settings_entity.dart';
import '../../1_domain/3_usecases/load_settings_usecase.dart';
import '../../1_domain/3_usecases/save_settings_usecase.dart';
import '../1_states/settings_state.dart';
import '../2_providers/settings_providers.dart';

/// 設定の状態管理 Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final LoadSettingsUsecase _loadUsecase;
  final SaveSettingsUsecase _saveUsecase;

  SettingsNotifier(this._loadUsecase, this._saveUsecase)
      : super(const SettingsState.initial());

  /// 設定をロード
  Future<void> load() async {
    state = const SettingsState.loading();
    try {
      final settings = await _loadUsecase();
      state = SettingsState.loaded(settings: settings);
    } catch (e) {
      state = SettingsState.error(e.toString());
    }
  }

  /// CLI パスを更新
  Future<void> updateCliPath(String path) async {
    final current = _currentSettings;
    if (current == null) return;
    final updated = current.copyWith(utakataCliPath: path);
    await _saveUsecase(updated);
    state = SettingsState.loaded(settings: updated);
  }

  /// プロジェクトルートを更新
  Future<void> updateProjectRoot(String? root) async {
    final current = _currentSettings;
    if (current == null) return;
    final updated = current.copyWith(projectRoot: root);
    await _saveUsecase(updated);
    state = SettingsState.loaded(settings: updated);
  }

  AppSettingsEntity? get _currentSettings => state.mapOrNull(
        loaded: (s) => s.settings,
      );
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(
    ref.read(loadSettingsUsecaseProvider),
    ref.read(saveSettingsUsecaseProvider),
  ),
);
