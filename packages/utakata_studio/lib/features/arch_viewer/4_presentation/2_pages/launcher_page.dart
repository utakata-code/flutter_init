import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/routing/path/app_paths.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../settings/3_application/3_notifiers/settings_notifier.dart';
import '../../../validation/3_application/3_notifiers/validation_notifier.dart';

/// ランチャー画面 — 起動直後に表示されるランディングページ
///
/// - 「プロジェクトを開く」→ フォルダ選択 → /project へ遷移
/// - 「アーキテクチャ管理」→ /architectures へ遷移
class LauncherPage extends HookConsumerWidget {
  const LauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StudioTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── ロゴ ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [StudioTheme.accentCyan, StudioTheme.accentPurple],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: StudioTheme.accentCyan.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // ── タイトル ──
            Text(
              'utakata studio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Architecture Viewer & Low-Code Tool',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StudioTheme.textMuted,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 48),

            // ── アクションボタン ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LauncherButton(
                  icon: Icons.folder_open_outlined,
                  label: 'プロジェクトを開く',
                  description: 'utakata プロジェクトフォルダを\n選択してワークスペースを開きます',
                  accentColor: StudioTheme.accentCyan,
                  onPressed: () => _openProject(context, ref),
                ),
                const SizedBox(width: 24),
                _LauncherButton(
                  icon: Icons.architecture_outlined,
                  label: 'アーキテクチャ管理',
                  description: '組み込みアーキテクチャテンプレートの\n一覧表示・詳細確認',
                  accentColor: StudioTheme.accentPurple,
                  onPressed: () => context.go(AppPaths.architectures),
                ),
              ],
            ),
            const SizedBox(height: 64),

            // ── バージョン情報 ──
            Text(
              'v0.3.0',
              style: TextStyle(
                color: StudioTheme.textMuted.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// プロジェクトフォルダを開き、/project へ遷移する
  Future<void> _openProject(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'utakata プロジェクトフォルダを選択',
    );
    if (result == null) return;

    await ref.read(settingsNotifierProvider.notifier).updateProjectRoot(result);
    ref
        .read(validationNotifierProvider.notifier)
        .loadAndValidate('$result/AI/architecture/arch_definition.yaml');

    if (context.mounted) {
      context.go(AppPaths.projectArchitecture);
    }
  }
}

/// ランチャー画面のアクションボタン
class _LauncherButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final VoidCallback onPressed;

  const _LauncherButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_LauncherButton> createState() => _LauncherButtonState();
}

class _LauncherButtonState extends State<_LauncherButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.06)
                : StudioTheme.surfaceBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.3)
                  : StudioTheme.borderColor,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: widget.accentColor,
              ),
              const SizedBox(height: 16),
              Text(
                widget.label,
                style: TextStyle(
                  color: StudioTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: StudioTheme.textMuted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
