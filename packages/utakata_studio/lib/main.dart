import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/studio_theme.dart';
import 'features/arch_editor/4_presentation/2_pages/studio_home_page.dart';

/// プロジェクトルートのパスを解決するプロバイダ
/// Flutter Desktop の場合、作業ディレクトリが build/ 配下になるため
/// 実行ファイルのパスからプロジェクトルートを推定する。
final projectRootProvider = Provider<String>((ref) {
  // 環境変数で明示的に指定されている場合はそれを優先
  final envRoot = Platform.environment['UTAKATA_PROJECT_ROOT'];
  if (envRoot != null && envRoot.isNotEmpty) return envRoot;

  // flutter run 時の作業ディレクトリを使用
  return Directory.current.path;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // デスクトップ用ウィンドウ初期化
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 820),
      minimumSize: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'utakata studio',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    debugPrint('Window manager initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: UtakataStudioApp(),
    ),
  );
}

class UtakataStudioApp extends StatelessWidget {
  const UtakataStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'utakata studio',
      debugShowCheckedModeBanner: false,
      theme: StudioTheme.darkTheme,
      home: const StudioHomePage(),
    );
  }
}
