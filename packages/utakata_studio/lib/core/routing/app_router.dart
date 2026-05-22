import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'path/app_paths.dart';
import '../../features/arch_viewer/4_presentation/2_pages/shell_layout_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/studio_home_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/features_page.dart';
import '../../features/arch_viewer/4_presentation/2_pages/dashboard_page.dart';
import '../../features/command_runner/4_presentation/2_pages/command_runner_page.dart';
import '../../features/settings/4_presentation/2_pages/settings_page.dart';

/// アプリ全体のルーター構成
///
/// ShellRoute でサイドバーを常時表示し、コンテンツ領域だけを切り替える。
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppPaths.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellLayoutPage(child: child),
        routes: [
          GoRoute(
            path: AppPaths.home,
            name: AppPaths.homeRouteName,
            builder: (context, state) => const StudioHomePage(),
          ),
          GoRoute(
            path: AppPaths.settings,
            name: AppPaths.settingsRouteName,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppPaths.health,
            name: AppPaths.healthRouteName,
            builder: (context, state) => const CommandRunnerPage(),
          ),
          GoRoute(
            path: AppPaths.features,
            name: AppPaths.featuresRouteName,
            builder: (context, state) => const FeaturesPage(),
          ),
          GoRoute(
            path: AppPaths.dashboard,
            name: AppPaths.dashboardRouteName,
            builder: (context, state) => const DashboardPage(),
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
