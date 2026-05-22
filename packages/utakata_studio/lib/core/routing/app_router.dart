import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'path/app_paths.dart';
import '../../features/arch_viewer/4_presentation/2_pages/studio_home_page.dart';
import '../../features/settings/4_presentation/2_pages/settings_page.dart';

/// アプリ全体のルーター構成
///
/// 画面パスは [AppPaths] から参照する。
/// v0.1.0 では単一画面 + 設定画面のシンプルな構成。
GoRouter createAppRouter() {  
  return GoRouter(
    initialLocation: AppPaths.home,
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
    ],
  );
}

/// GoRouter の Provider
final appRouterProvider = Provider<GoRouter>(
  (ref) => createAppRouter(),
);
