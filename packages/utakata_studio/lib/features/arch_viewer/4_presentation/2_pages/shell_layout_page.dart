import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/routing/path/app_paths.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../validation/3_application/3_notifiers/validation_notifier.dart';
import '../1_widgets/3_organisms/sidebar_organism.dart';

/// シェルレイアウト: サイドバー + コンテンツ領域
///
/// 全画面で共通のサイドバーを表示し、右側のコンテンツ領域だけを
/// go_router のルートに応じて切り替える。
class ShellLayoutPage extends HookConsumerWidget {
  final Widget child;
  const ShellLayoutPage({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationState = ref.watch(validationNotifierProvider);
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: StudioTheme.darkBg,
      body: Row(
        children: [
          // ── 左ペイン: サイドバー（常時表示） ──
          SidebarOrganism(
            validationState: validationState,
            activeRoute: currentPath,
            callbacks: (
              onSettingsTap: () => context.go(AppPaths.projectSettings),
              onHealthTap: () => context.go(AppPaths.projectHealth),
              onHomeTap: () => context.go(AppPaths.projectArchitecture),
              onFeaturesTap: () => context.go(AppPaths.projectFeatures),
              onDashboardTap: () => context.go(AppPaths.projectDashboard),
              onSpecTap: () => context.go(AppPaths.projectSpec),
              onPlanTap: () => context.go(AppPaths.projectPlan),
              onOpenProject: () => context.go(AppPaths.launcher),
            ),
          ),
          // ── 右ペイン: ルートに応じたコンテンツ ──
          Expanded(child: child),
        ],
      ),
    );
  }
}
