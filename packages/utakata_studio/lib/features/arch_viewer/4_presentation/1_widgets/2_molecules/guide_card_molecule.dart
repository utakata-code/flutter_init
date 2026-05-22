import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// ガイドカード
class GuideCardMolecule extends StatelessWidget {
  final GuideEntity guide;
  const GuideCardMolecule({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioTheme.surfaceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StudioTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(guide.title,
            style: const TextStyle(
                color: StudioTheme.accentGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
        const SizedBox(height: 4),
        Text(guide.layerPath,
            style: const TextStyle(
                color: StudioTheme.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace')),
      ]),
    );
  }
}
