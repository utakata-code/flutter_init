import 'package:flutter/material.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// 右ペイン: 全ディレクトリの依存関係グラフ
///
/// 4層 × サブディレクトリをノードとして描画し、
/// レイヤー間・ディレクトリ間の依存を矢印で示す。
class LayerTreeVisualizerOrganism extends StatelessWidget {
  final List<LayerDefinitionEntity> layers;
  const LayerTreeVisualizerOrganism({super.key, required this.layers});

  static const _layerColors = [
    StudioTheme.accentCyan,    // 1_domain
    StudioTheme.accentGreen,   // 2_infrastructure
    StudioTheme.accentYellow,  // 3_application
    StudioTheme.accentPurple,  // 4_presentation
  ];

  /// レイヤー内のサブディレクトリ間の依存関係
  /// {layerIndex: [[fromDirIndex, toDirIndex], ...]}
  static const _intraDirDeps = <int, List<List<int>>>{
    // domain: entities → repositories → usecases
    0: [[0, 1], [1, 2]],
    // infrastructure: models ← data_sources → repositories
    1: [[0, 4], [1, 4], [2, 4]],
    // application: states → notifiers, providers → notifiers
    2: [[0, 2], [1, 2]],
    // presentation: atoms → molecules → organisms → pages
    3: [[0, 1], [1, 2], [2, 3]],
  };

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
            border: Border(bottom: BorderSide(color: StudioTheme.borderColor)),
          ),
          child: Row(children: [
            const Icon(Icons.account_tree_outlined,
                size: 16, color: StudioTheme.accentPurple),
            const SizedBox(width: 8),
            Text('DEPENDENCY GRAPH',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: StudioTheme.accentPurple)),
          ]),
        ),
        // ── グラフ本体 ──
        Expanded(
          child: layers.isEmpty
              ? Center(
                  child: Text('No layers loaded',
                      style: Theme.of(context).textTheme.bodySmall))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < layers.length; i++) ...[
                        _LayerGroupCard(
                          layer: layers[i],
                          color: _layerColors[i % _layerColors.length],
                          intraDeps: _intraDirDeps[i] ?? [],
                        ),
                        if (i < layers.length - 1)
                          _InterLayerArrow(
                            fromColor: _layerColors[i % _layerColors.length],
                            toColor: _layerColors[(i + 1) % _layerColors.length],
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ]),
    );
  }
}

/// レイヤーグループカード: レイヤー名 + サブディレクトリノード + 内部依存矢印
class _LayerGroupCard extends StatelessWidget {
  final LayerDefinitionEntity layer;
  final Color color;
  final List<List<int>> intraDeps;

  const _LayerGroupCard({
    required this.layer,
    required this.color,
    this.intraDeps = const [],
  });

  @override
  Widget build(BuildContext context) {
    // ディレクトリ名を簡潔化
    final dirs = layer.dirs.map(_simplifyDirName).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── レイヤー名ヘッダー ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(layer.name,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const Spacer(),
                Text('${dirs.length} dirs',
                    style: TextStyle(
                        color: color.withValues(alpha: 0.5), fontSize: 10)),
              ],
            ),
          ),
          // ── サブディレクトリノード群 ──
          Padding(
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _DirNodesWithArrows(
                  dirs: dirs,
                  color: color,
                  intraDeps: intraDeps,
                  maxWidth: constraints.maxWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _simplifyDirName(String dir) {
    // "2_data_sources/1_local/exceptions" → "local/exceptions"
    // "1_widgets/1_atoms" → "atoms"
    final parts = dir.split('/');
    return parts
        .map((p) => p.replaceAll(RegExp(r'^\d+_'), ''))
        .where((p) => p != 'widgets' && p != 'data_sources')
        .join('/');
  }
}

/// サブディレクトリノード + 内部依存矢印の描画
class _DirNodesWithArrows extends StatelessWidget {
  final List<String> dirs;
  final Color color;
  final List<List<int>> intraDeps;
  final double maxWidth;

  const _DirNodesWithArrows({
    required this.dirs,
    required this.color,
    required this.intraDeps,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // exceptions ディレクトリをフィルタリング
    final filteredDirs = <_DirEntry>[];
    for (int i = 0; i < dirs.length; i++) {
      if (!dirs[i].contains('exceptions')) {
        filteredDirs.add(_DirEntry(dirs[i], i));
      }
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (int i = 0; i < filteredDirs.length; i++) ...[
          _DirNode(
            name: filteredDirs[i].name,
            color: color,
          ),
          // 同一行内の矢印（簡略化: 連続ノード間は → で表現）
          if (i < filteredDirs.length - 1 &&
              _hasDirectDep(filteredDirs[i].originalIndex,
                  filteredDirs[i + 1].originalIndex))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Icon(Icons.arrow_forward,
                  size: 14, color: color.withValues(alpha: 0.4)),
            ),
        ],
      ],
    );
  }

  bool _hasDirectDep(int from, int to) {
    return intraDeps.any((dep) => dep[0] == from && dep[1] == to);
  }
}

class _DirEntry {
  final String name;
  final int originalIndex;
  const _DirEntry(this.name, this.originalIndex);
}

/// 個別ディレクトリノード
class _DirNode extends StatelessWidget {
  final String name;
  final Color color;

  const _DirNode({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 12, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(name,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

/// レイヤー間の接続矢印
class _InterLayerArrow extends StatelessWidget {
  final Color fromColor;
  final Color toColor;

  const _InterLayerArrow({required this.fromColor, required this.toColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 2,
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  fromColor.withValues(alpha: 0.4),
                  toColor.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down,
              size: 16,
              color: toColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
