import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// レイヤーサマリーカード
class LayerSummaryCardMolecule extends StatelessWidget {
  final LayerDefinitionEntity layer;
  final int index;

  const LayerSummaryCardMolecule(
      {super.key, required this.layer, required this.index});

  static const _colors = [
    StudioTheme.accentCyan,
    StudioTheme.accentGreen,
    StudioTheme.accentYellow,
    StudioTheme.accentPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
        leading: Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        title: Text(layer.name,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text('${layer.dirs.length} directories',
            style: Theme.of(context).textTheme.bodySmall),
        children: layer.dirs
            .map((dir) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Icon(Icons.folder_outlined,
                        size: 14, color: color.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Text(dir,
                        style: TextStyle(
                            color: StudioTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace')),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}
