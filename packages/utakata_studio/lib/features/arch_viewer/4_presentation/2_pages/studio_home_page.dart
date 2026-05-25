import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../layer_visualizer/3_application/1_states/layer_visualizer_state.dart';
import '../../../layer_visualizer/3_application/3_notifiers/layer_visualizer_notifier.dart';
import '../../../validation/3_application/1_states/validation_state.dart';
import '../../../validation/3_application/3_notifiers/validation_notifier.dart';
import '../1_widgets/3_organisms/arch_definition_viewer_organism.dart';
import '../../../layer_visualizer/4_presentation/1_widgets/3_organisms/layer_tree_visualizer_organism.dart';

/// Architecture ビューア（コンテンツ領域のみ）
///
/// サイドバーは ShellLayoutPage が担当するため、ここではコンテンツのみ。
class StudioHomePage extends HookConsumerWidget {
  const StudioHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationState = ref.watch(validationNotifierProvider);
    final layerState = ref.watch(layerVisualizerNotifierProvider);

    // バリデーション完了時にレイヤービジュアライザへ自動連携
    ref.listen<ValidationState>(validationNotifierProvider, (prev, next) {
      next.mapOrNull(
        loaded: (s) {
          ref
              .read(layerVisualizerNotifierProvider.notifier)
              .updateLayers(s.result.layers);
        },
      );
    });

    return Container(
      color: StudioTheme.darkBg,
      child: Row(
        children: [
          // ── 中央ペイン: アーキテクチャビューア ──
          Expanded(
            flex: 5,
            child: validationState.when(
              initial: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open,
                        size: 48, color: StudioTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('プロジェクトフォルダを開いてください',
                        style: TextStyle(
                            color: StudioTheme.textMuted, fontSize: 14)),
                  ],
                ),
              ),
              loading: (_) => const Center(
                child: CircularProgressIndicator(
                    color: StudioTheme.accentCyan),
              ),
              loaded: (result, _) =>
                  ArchDefinitionViewerOrganism(result: result),
              error: (message, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: StudioTheme.accentRed),
                    const SizedBox(height: 16),
                    Text(message,
                        style: const TextStyle(
                            color: StudioTheme.accentRed, fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          // ── 右ペイン: レイヤービジュアライザ ──
          Expanded(
            flex: 4,
            child: layerState.when(
              initial: () =>
                  const LayerTreeVisualizerOrganism(layers: []),
              loaded: (layers) =>
                  LayerTreeVisualizerOrganism(layers: layers),
            ),
          ),
        ],
      ),
    );
  }
}
