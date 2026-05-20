import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';

import '../../../../../core/theme/studio_theme.dart';

/// アーキテクチャの層構造をビジュアルに描画するウィジェット (Organism)
class LayerTreeVisualizerWidget extends StatelessWidget {
  final List<LayerDefinitionEntity> layers;

  const LayerTreeVisualizerWidget({
    super.key,
    required this.layers,
  });

  @override
  Widget build(BuildContext context) {
    if (layers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear, color: StudioTheme.textMuted.withOpacity(0.4), size: 48),
            const SizedBox(height: 16),
            Text(
              'レイヤー定義がありません',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StudioTheme.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: layers.length,
      itemBuilder: (context, index) {
        final layer = layers[index];
        final isLast = index == layers.length - 1;

        // 層に応じたグラデーション色
        final hue = 180.0 + (index * 28);
        final topColor = HSLColor.fromAHSL(1, hue, 0.75, 0.4).toColor();
        final bottomColor = HSLColor.fromAHSL(1, hue + 15, 0.7, 0.32).toColor();

        return Column(
          children: [
            _LayerCard(
              layer: layer,
              index: index,
              topColor: topColor,
              bottomColor: bottomColor,
            ),
            if (!isLast) const _DependencyArrow(),
          ],
        );
      },
    );
  }
}

class _LayerCard extends StatelessWidget {
  final LayerDefinitionEntity layer;
  final int index;
  final Color topColor;
  final Color bottomColor;

  const _LayerCard({
    required this.layer,
    required this.index,
    required this.topColor,
    required this.bottomColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topColor, bottomColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: topColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'L${index + 1}',
                    style: const TextStyle(
                      color: StudioTheme.accentCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  layer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${layer.dirs.length} dirs',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            iconColor: Colors.white60,
            collapsedIconColor: Colors.white30,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: layer.dirs.isEmpty
                ? const [
                    Text(
                      '  (空のフォルダ階層)',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ]
                : layer.dirs
                    .map((dir) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.folder_open_outlined,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                dir,
                                style: const TextStyle(
                                  fontFamily: 'Consolas',
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
          ),
        ),
      ),
    );
  }
}

class _DependencyArrow extends StatelessWidget {
  const _DependencyArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Container(width: 2, height: 14, color: StudioTheme.accentCyan.withOpacity(0.3)),
          Icon(Icons.keyboard_arrow_down,
              color: StudioTheme.accentCyan.withOpacity(0.5), size: 16),
          Container(width: 2, height: 4, color: StudioTheme.accentCyan.withOpacity(0.3)),
        ],
      ),
    );
  }
}
