import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';
import '../../../../validation/1_domain/1_entities/validation_result_entity.dart';
import '../2_molecules/layer_summary_card_molecule.dart';
import '../2_molecules/naming_rule_card_molecule.dart';
import '../2_molecules/core_module_card_molecule.dart';
import '../2_molecules/guide_card_molecule.dart';

/// 中央ペイン: アーキテクチャ定義のセクション別ビューア（タブ形式）
class ArchDefinitionViewerOrganism extends StatefulWidget {
  final ValidationResultEntity result;
  const ArchDefinitionViewerOrganism({super.key, required this.result});

  @override
  State<ArchDefinitionViewerOrganism> createState() =>
      _ArchDefinitionViewerOrganismState();
}

class _ArchDefinitionViewerOrganismState
    extends State<ArchDefinitionViewerOrganism>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

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
            border: Border(bottom: BorderSide(color: StudioTheme.borderColor)),
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
            Text('v0.2.0 — viewer mode',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ]),
        ),
        // ── タブバー ──
        Container(
          height: 36,
          decoration: const BoxDecoration(
            color: StudioTheme.darkBg,
            border: Border(bottom: BorderSide(color: StudioTheme.borderColor)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            indicatorColor: StudioTheme.accentCyan,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelColor: StudioTheme.textPrimary,
            unselectedLabelColor: StudioTheme.textMuted,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            tabs: [
              _buildTab('LAYERS', r.layers.length, StudioTheme.accentCyan),
              _buildTab('NAMING', r.namingRules.length, StudioTheme.accentYellow),
              _buildTab('CORE', r.coreModules.length, StudioTheme.accentPurple),
              _buildTab('GUIDES', r.guides.length, StudioTheme.accentGreen),
            ],
          ),
        ),
        // ── タブコンテンツ ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── LAYERS ──
              _buildListView(
                items: r.layers,
                emptyIcon: Icons.layers_outlined,
                emptyText: 'レイヤー定義がありません',
                builder: (layer, index) =>
                    LayerSummaryCardMolecule(layer: layer, index: index),
              ),
              // ── NAMING RULES ──
              _buildListView(
                items: r.namingRules,
                emptyIcon: Icons.rule_outlined,
                emptyText: '命名規則がありません',
                builder: (rule, _) => NamingRuleCardMolecule(rule: rule),
              ),
              // ── CORE MODULES ──
              _buildListView(
                items: r.coreModules,
                emptyIcon: Icons.widgets_outlined,
                emptyText: 'コアモジュールがありません',
                builder: (module, _) =>
                    CoreModuleCardMolecule(module: module),
              ),
              // ── GUIDES ──
              _buildListView(
                items: r.guides,
                emptyIcon: Icons.menu_book_outlined,
                emptyText: 'ガイドがありません',
                builder: (guide, _) => GuideCardMolecule(guide: guide),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTab(String label, int count, Color color) {
    return Tab(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListView<T>({
    required List<T> items,
    required IconData emptyIcon,
    required String emptyText,
    required Widget Function(T item, int index) builder,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 40, color: StudioTheme.textMuted),
            const SizedBox(height: 8),
            Text(emptyText,
                style: TextStyle(color: StudioTheme.textMuted, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: items.length,
      itemBuilder: (context, index) => builder(items[index], index),
    );
  }
}
