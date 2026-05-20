import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/studio_theme.dart';
import 'features/arch_editor/4_presentation/2_pages/studio_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
