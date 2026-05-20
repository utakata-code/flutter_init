import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/studio_theme.dart';
import '../../../validation/3_application/2_providers/validation_providers.dart';
import '../../../validation/3_application/3_notifiers/yaml_validation_notifier.dart';
import '../../../yaml_viewer/4_presentation/1_widgets/3_organisms/yaml_editor_widget.dart';
import '../../../arch_visualizer/4_presentation/1_widgets/3_organisms/layer_tree_visualizer_widget.dart';
import '../1_widgets/3_organisms/sidebar_widget.dart';

/// utakata studio のメインページ
///
/// 3ペイン構成: 左サイドバー / 中央YAMLエディタ / 右ビジュアライザ
class StudioHomePage extends HookConsumerWidget {
  const StudioHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(yamlValidationProvider);
    final textController = useTextEditingController();

    // 初回ロード: プロジェクトの arch_definition.yaml を読み込み
    useEffect(() {
      Future.microtask(() {
        ref.read(yamlValidationProvider.notifier).loadFromFile(
              'AI/architecture/arch_definition.yaml',
            );
      });
      return null;
    }, const []);

    // ロード完了時にテキストコントローラへ反映（1度だけ）
    final hasLoaded = useRef(false);
    useEffect(() {
      if (!state.isLoading && !hasLoaded.value && state.yamlContent.isNotEmpty) {
        textController.text = state.yamlContent;
        hasLoaded.value = true;
      }
      return null;
    }, [state.isLoading, state.yamlContent]);

    return Scaffold(
      backgroundColor: StudioTheme.darkBg,
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: StudioTheme.accentCyan),
            )
          : Row(
              children: [
                // ── 左ペイン: Sidebar ──
                SidebarWidget(state: state),

                const VerticalDivider(width: 1, thickness: 1),

                // ── 中央ペイン: YAML Editor ──
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _PaneHeader(
                        title: 'YAML DEFINITION',
                        icon: Icons.code,
                        actions: [
                          _HeaderAction(
                            icon: Icons.save_outlined,
                            tooltip: '保存',
                            onPressed: () {
                              ref
                                  .read(yamlValidationProvider.notifier)
                                  .saveToFile(textController.text);
                            },
                          ),
                          _HeaderAction(
                            icon: Icons.refresh,
                            tooltip: 'リロード',
                            onPressed: () {
                              ref
                                  .read(yamlValidationProvider.notifier)
                                  .loadFromFile('AI/architecture/arch_definition.yaml')
                                  .then((_) {
                                textController.text =
                                    ref.read(yamlValidationProvider).yamlContent;
                              });
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: YamlEditorWidget(
                            controller: textController,
                            isValid: state.isValid,
                            onChanged: (value) {
                              ref
                                  .read(yamlValidationProvider.notifier)
                                  .validateText(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(width: 1, thickness: 1),

                // ── 右ペイン: Visualizer ──
                Expanded(
                  flex: 4,
                  child: Container(
                    color: StudioTheme.sidebarBg,
                    child: Column(
                      children: [
                        const _PaneHeader(
                          title: 'ARCHITECTURE VISUALIZER',
                          icon: Icons.remove_red_eye_outlined,
                        ),
                        Expanded(
                          child: state.isValid
                              ? LayerTreeVisualizerWidget(
                                  layers: state.result?.layers ?? [],
                                )
                              : _VisualizerErrorPlaceholder(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// ペインヘッダー (各ペインの上部バー)
class _PaneHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;

  const _PaneHeader({
    required this.title,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: StudioTheme.borderColor)),
      ),
      child: Row(
        children: [
          Icon(icon, color: StudioTheme.accentCyan, size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: StudioTheme.textSecondary,
                ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// ヘッダーのアクションボタン
class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: StudioTheme.textMuted,
        hoverColor: StudioTheme.accentCyan.withOpacity(0.1),
        onPressed: onPressed,
      ),
    );
  }
}

/// ビジュアライザのエラー時プレースホルダー
class _VisualizerErrorPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              color: StudioTheme.accentRed.withOpacity(0.4), size: 48),
          const SizedBox(height: 16),
          const Text(
            'ビジュアライザを一時停止中',
            style: TextStyle(
              color: StudioTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'YAML エラーを修正すると再描画されます。',
            style: TextStyle(color: StudioTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
