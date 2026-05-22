import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';
import '../1_atoms/dependency_arrow_atom.dart';
import '../2_molecules/layer_card_molecule.dart';

/// 右ペイン: レイヤー構造全体描画
class LayerTreeVisualizerOrganism extends StatelessWidget {
  final List<LayerDefinitionEntity> layers;
  const LayerTreeVisualizerOrganism({super.key, required this.layers});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StudioTheme.editorBg,
      child: Column(children: [
        // ── ヘッダー ──
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: StudioTheme.sidebarBg,
            border:
                Border(bottom: BorderSide(color: StudioTheme.borderColor)),
          ),
          child: Row(children: [
            const Icon(Icons.account_tree_outlined,
                size: 16, color: StudioTheme.accentPurple),
            const SizedBox(width: 8),
            Text('LAYER VISUALIZER',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: StudioTheme.accentPurple)),
          ]),
        ),
        // ── レイヤーツリー ──
        Expanded(
          child: layers.isEmpty
              ? Center(
                  child: Text('No layers loaded',
                      style: Theme.of(context).textTheme.bodySmall))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: layers.length * 2 - 1,
                  itemBuilder: (context, index) {
                    if (index.isOdd) {
                      return const Center(child: DependencyArrowAtom());
                    }
                    final layerIndex = index ~/ 2;
                    return LayerCardMolecule(
                      layer: layers[layerIndex],
                      index: layerIndex,
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
