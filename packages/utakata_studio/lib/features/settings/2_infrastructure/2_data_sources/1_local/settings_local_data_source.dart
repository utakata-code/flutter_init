import 'package:shared_preferences/shared_preferences.dart';
import '../../../2_infrastructure/1_models/app_settings_model.dart';

/// SharedPreferences を使った設定の永続化
///
/// エンティティではなくモデルを返す。Entity 変換はリポジトリ層で行う。
class SettingsLocalDataSource {
  static const _keyCliPath = 'utakata_cli_path';
  static const _keyProjectRoot = 'project_root';

  /// モデルとして設定を読み込む
  Future<AppSettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsModel(
      utakataCliPath: prefs.getString(_keyCliPath) ?? 'utakata',
      projectRoot: prefs.getString(_keyProjectRoot),
    );
  }

  /// モデルから設定を保存する
  Future<void> save(AppSettingsModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCliPath, model.utakataCliPath);
    if (model.projectRoot != null) {
      await prefs.setString(_keyProjectRoot, model.projectRoot!);
    } else {
      await prefs.remove(_keyProjectRoot);
    }
  }
}
