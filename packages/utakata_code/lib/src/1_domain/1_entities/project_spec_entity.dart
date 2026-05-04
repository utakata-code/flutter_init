/// プロジェクト仕様エンティティ
///
/// utakata create コマンドで収集するプロジェクトの仕様を表す。
class ProjectSpecEntity {
  /// アプリ名（ディレクトリ名として使用。スペース・記号を含む場合あり）
  final String appName;

  /// 正規化後のプロジェクト名（snake_case）
  final String projectName;

  /// パッケージ組織名（例: 'com.example'）
  final String org;

  /// 対象プラットフォーム（例: 'android,ios,web,macos'）
  final String platforms;

  /// プロジェクトの説明
  final String description;

  /// 使用するアーキテクチャの識別子
  final String architectureId;

  /// レイアウトテンプレートの識別子（null = なし）
  final String? layoutId;

  const ProjectSpecEntity({
    required this.appName,
    required this.projectName,
    required this.org,
    this.platforms = 'android,ios,web,macos',
    this.description = 'Flutter app',
    this.architectureId = 'clean_architecture',
    this.layoutId,
  });

  @override
  String toString() =>
      'ProjectSpecEntity(app: $appName, arch: $architectureId)';
}
