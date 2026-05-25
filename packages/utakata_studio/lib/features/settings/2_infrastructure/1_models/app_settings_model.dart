import '../../1_domain/1_entities/app_settings_entity.dart';

/// AppSettingsEntity ↔ Map 変換モデル
///
/// SharedPreferences のキーバリューと Entity 間の変換を担当する。
class AppSettingsModel {
  final String utakataCliPath;
  final String? projectRoot;

  const AppSettingsModel({
    required this.utakataCliPath,
    this.projectRoot,
  });

  /// Map からモデルを生成
  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      utakataCliPath: map['utakata_cli_path'] as String? ?? 'utakata',
      projectRoot: map['project_root'] as String?,
    );
  }

  /// モデルを Map に変換
  Map<String, dynamic> toMap() {
    return {
      'utakata_cli_path': utakataCliPath,
      if (projectRoot != null) 'project_root': projectRoot,
    };
  }

  /// ドメインエンティティに変換
  AppSettingsEntity toEntity() {
    return AppSettingsEntity(
      utakataCliPath: utakataCliPath,
      projectRoot: projectRoot,
    );
  }

  /// ドメインエンティティからモデルを生成
  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) {
    return AppSettingsModel(
      utakataCliPath: entity.utakataCliPath,
      projectRoot: entity.projectRoot,
    );
  }
}
