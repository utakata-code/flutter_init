import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// 命名規則カード
class NamingRuleCardMolecule extends StatelessWidget {
  final NamingRuleEntity rule;
  const NamingRuleCardMolecule({super.key, required this.rule});

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
        Row(children: [
          const Icon(Icons.folder_outlined,
              size: 14, color: StudioTheme.accentYellow),
          const SizedBox(width: 6),
          Expanded(
              child: Text(rule.dirPattern,
                  style: const TextStyle(
                      color: StudioTheme.accentYellow,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.description_outlined,
              size: 14, color: StudioTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
              child: Text(rule.filePattern,
                  style: const TextStyle(
                      color: StudioTheme.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace'))),
        ]),
        if (rule.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(rule.description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ]),
    );
  }
}
