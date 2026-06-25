import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'path/app_paths.dart';
import '../../features/arch_viewer/4_presentation/2_pages/launcher_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/architectures_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/shell_layout_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/studio_home_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/doc_viewer_page.dart';
import '../../features/feature_viewer/4_presentation/2_pages/features_page.dart';
import '../../features/dashboard/4_presentation/2_pages/dashboard_page.dart';
import '../../features/command_runner/4_presentation/2_pages/command_runner_page.dart';
import '../../features/settings/4_presentation/2_pages/settings_page.dart';

/// アプリ全体のルーター構成（2層構造）
///
/// - `/` : ランチャー画面
/// - `/architectures` : アーキテクチャ管理画面
/// - `/project/**` : プロジェクトワークスペース（ShellRoute でサイドバー付き）
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppPaths.launcher,
    routes: [
      // ── ランチャー画面 ──
      GoRoute(
        path: AppPaths.launcher,
        name: AppPaths.launcherRouteName,
        builder: (context, state) => const LauncherPage(),
      ),

      // ── アーキテクチャ管理画面 ──
      GoRoute(
        path: AppPaths.architectures,
        name: AppPaths.architecturesRouteName,
        builder: (context, state) => const ArchitecturesPage(),
      ),

      // ── プロジェクトワークスペース ──
      ShellRoute(
        builder: (context, state, child) => ShellLayoutPage(child: child),
        routes: [
          GoRoute(
            path: AppPaths.projectArchitecture,
            name: AppPaths.projectArchitectureRouteName,
            builder: (context, state) => const StudioHomePage(),
          ),
          GoRoute(
            path: AppPaths.projectFeatures,
            name: AppPaths.projectFeaturesRouteName,
            builder: (context, state) => const FeaturesPage(),
          ),
          GoRoute(
            path: AppPaths.projectHealth,
            name: AppPaths.projectHealthRouteName,
            builder: (context, state) => const CommandRunnerPage(),
          ),
          GoRoute(
            path: AppPaths.projectDashboard,
            name: AppPaths.projectDashboardRouteName,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppPaths.projectSpec,
            name: AppPaths.projectSpecRouteName,
            builder: (context, state) => const SpecViewerPage(),
          ),
          GoRoute(
            path: AppPaths.projectPlan,
            name: AppPaths.projectPlanRouteName,
            builder: (context, state) => const PlanViewerPage(),
          ),
          GoRoute(
            path: AppPaths.projectSettings,
            name: AppPaths.projectSettingsRouteName,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

/// GoRouter の Provider
final appRouterProvider = Provider<GoRouter>(
  (ref) => createAppRouter(),
);
