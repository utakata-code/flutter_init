import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/routing/app_router.dart';
import 'features/settings/3_application/1_states/settings_state.dart';
import 'features/settings/3_application/3_notifiers/settings_notifier.dart';
import 'features/validation/3_application/3_notifiers/validation_notifier.dart';

/// アプリのブートシーケンス
///
/// 責務:
/// - フレームワーク初期化
/// - 例外捕捉の設定
/// - Core の初期化（ルーター等）
/// - ProviderScope の用意と runApp
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // デスクトップウィンドウ設定
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(1024, 600),
      center: true,
      title: 'utakata studio',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Core 初期化
    final router = createAppRouter();

    // ProviderScope + override で起動
    final container = ProviderContainer(overrides: [
      appRouterProvider.overrideWithValue(router),
    ]);

    // 設定をロード → arch_definition.yaml をバリデーション
    await container.read(settingsNotifierProvider.notifier).load();
    final settingsState = container.read(settingsNotifierProvider);
    final projectRoot = settingsState.mapOrNull(
          loaded: (s) => s.settings.projectRoot,
        ) ??
        '.';

    container
        .read(validationNotifierProvider.notifier)
        .loadAndValidate('$projectRoot/AI/architecture/arch_definition.yaml');

    runApp(UncontrolledProviderScope(
      container: container,
      child: const App(),
    ));
  }, (error, stack) {
    // ログ集約（将来: クラッシュレポート送信）
    debugPrint('Uncaught error: $error\n$stack');
  });
}
