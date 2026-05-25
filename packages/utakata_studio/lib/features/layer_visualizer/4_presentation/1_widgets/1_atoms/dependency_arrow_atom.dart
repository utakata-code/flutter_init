import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';

/// レイヤー間の依存方向を示す矢印
class DependencyArrowAtom extends StatelessWidget {
  final Color color;
  const DependencyArrowAtom({super.key, this.color = StudioTheme.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Icon(Icons.arrow_downward, size: 16, color: color),
    );
  }
}
