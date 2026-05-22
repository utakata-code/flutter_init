import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';
import '../../../../validation/1_domain/1_entities/validation_result_entity.dart';
import '../1_atoms/section_header_atom.dart';
import '../2_molecules/layer_summary_card_molecule.dart';
import '../2_molecules/naming_rule_card_molecule.dart';
import '../2_molecules/core_module_card_molecule.dart';
import '../2_molecules/guide_card_molecule.dart';

/// 中央ペイン: アーキテクチャ定義のセクション別ビューア
class ArchDefinitionViewerOrganism extends StatelessWidget {
  final ValidationResultEntity result;
  const ArchDefinitionViewerOrganism({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: StudioTheme.editorBg,
        border: Border(
          left: BorderSide(color: StudioTheme.borderColor),
          right: BorderSide(color: StudioTheme.borderColor),
        ),
      ),
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
            const Icon(Icons.architecture,
                size: 16, color: StudioTheme.accentCyan),
            const SizedBox(width: 8),
            Text('ARCHITECTURE VIEWER',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: StudioTheme.accentCyan)),
            const Spacer(),
            Text('v0.1.0 — viewer mode',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ]),
        ),
        // ── コンテンツ ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              if (result.layers.isNotEmpty) ...[
                SectionHeaderAtom(
                    title: 'LAYERS',
                    count: result.layers.length,
                    icon: Icons.layers_outlined,
                    color: StudioTheme.accentCyan),
                ...result.layers.asMap().entries.map((e) =>
                    LayerSummaryCardMolecule(layer: e.value, index: e.key)),
                const SizedBox(height: 16),
              ],
              if (result.namingRules.isNotEmpty) ...[
                SectionHeaderAtom(
                    title: 'NAMING RULES',
                    count: result.namingRules.length,
                    icon: Icons.rule_outlined,
                    color: StudioTheme.accentYellow),
                ...result.namingRules
                    .map((r) => NamingRuleCardMolecule(rule: r)),
                const SizedBox(height: 16),
              ],
              if (result.coreModules.isNotEmpty) ...[
                SectionHeaderAtom(
                    title: 'CORE MODULES',
                    count: result.coreModules.length,
                    icon: Icons.widgets_outlined,
                    color: StudioTheme.accentPurple),
                ...result.coreModules
                    .map((m) => CoreModuleCardMolecule(module: m)),
                const SizedBox(height: 16),
              ],
              if (result.guides.isNotEmpty) ...[
                SectionHeaderAtom(
                    title: 'GUIDES',
                    count: result.guides.length,
                    icon: Icons.menu_book_outlined,
                    color: StudioTheme.accentGreen),
                ...result.guides.map((g) => GuideCardMolecule(guide: g)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}
