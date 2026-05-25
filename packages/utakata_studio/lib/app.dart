import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/studio_theme.dart';

/// アプリ最上位ウィジェット
///
/// テーマ・ルーティング・グローバル設定を構成する。
/// 重い初期化は行わず、main.dart で完了済みの依存を受け取るのみ。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'utakata studio',
      debugShowCheckedModeBanner: false,
      theme: StudioTheme.darkTheme,
      routerConfig: router,
    );
  }
}
