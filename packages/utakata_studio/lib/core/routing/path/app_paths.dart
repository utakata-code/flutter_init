/// 画面パスの定数定義
///
/// すべての画面パスとルート名をここに集約する。
/// UI / フィーチャー側はこの定数を参照して遷移を実行する。
class AppPaths {
  AppPaths._();

  // ── ランチャー ──
  static const launcher = '/';
  static const launcherRouteName = 'launcher';

  // ── アーキテクチャ管理 ──
  static const architectures = '/architectures';
  static const architecturesRouteName = 'architectures';

  // ── プロジェクトワークスペース ──
  static const project = '/project';
  static const projectRouteName = 'project';

  static const projectArchitecture = '/project';
  static const projectArchitectureRouteName = 'projectArchitecture';

  static const projectFeatures = '/project/features';
  static const projectFeaturesRouteName = 'projectFeatures';

  static const projectHealth = '/project/health';
  static const projectHealthRouteName = 'projectHealth';

  static const projectDashboard = '/project/dashboard';
  static const projectDashboardRouteName = 'projectDashboard';

  static const projectSpec = '/project/spec';
  static const projectSpecRouteName = 'projectSpec';

  static const projectPlan = '/project/plan';
  static const projectPlanRouteName = 'projectPlan';

  static const projectSettings = '/project/settings';
  static const projectSettingsRouteName = 'projectSettings';
}
