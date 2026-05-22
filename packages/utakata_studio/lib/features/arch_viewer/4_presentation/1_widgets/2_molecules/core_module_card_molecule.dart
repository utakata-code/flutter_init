import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// コアモジュールカード
class CoreModuleCardMolecule extends StatelessWidget {
  final CoreModuleEntity module;
  const CoreModuleCardMolecule({super.key, required this.module});

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
      child: Row(children: [
        const Icon(Icons.extension_outlined,
            size: 14, color: StudioTheme.accentPurple),
        const SizedBox(width: 8),
        Text(module.id,
            style: const TextStyle(
                color: StudioTheme.accentPurple,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(module.path,
                style: const TextStyle(
                    color: StudioTheme.textSecondary,
                    fontSize: 12,
                    fontFamily: 'monospace'))),
      ]),
    );
  }
}
