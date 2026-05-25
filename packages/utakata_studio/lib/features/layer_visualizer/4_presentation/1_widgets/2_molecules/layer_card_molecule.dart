import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// 個別レイヤーのグラデーションカード
class LayerCardMolecule extends StatelessWidget {
  final LayerDefinitionEntity layer;
  final int index;
  const LayerCardMolecule(
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(layer.name,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          Text('${layer.dirs.length}',
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
        if (layer.dirs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: layer.dirs
                .map((d) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(d,
                          style: TextStyle(
                              color: color.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontFamily: 'monospace')),
                    ))
                .toList(),
          ),
        ],
      ]),
    );
  }
}
