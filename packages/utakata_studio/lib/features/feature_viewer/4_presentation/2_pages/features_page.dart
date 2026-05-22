import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yaml/yaml.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../settings/3_application/1_states/settings_state.dart';
import '../../../settings/3_application/3_notifiers/settings_notifier.dart';

/// Features 画面: feature_request.yaml のビジュアルビューア
class FeaturesPage extends HookConsumerWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsNotifierProvider);

    final projectRoot = switch (settingsState) {
      SettingsStateLoaded(:final settings) => settings.projectRoot,
      _ => null,
    };

    return Container(
      color: StudioTheme.editorBg,
      child: Column(
        children: [
          // ── ヘッダー ──
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: StudioTheme.sidebarBg,
              border: Border(bottom: BorderSide(color: StudioTheme.borderColor)),
            ),
            child: Row(children: [
              const Icon(Icons.featured_play_list, size: 16, color: StudioTheme.accentPurple),
              const SizedBox(width: 8),
              Text('FEATURES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: StudioTheme.accentPurple,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          // ── コンテンツ ──
          Expanded(
            child: projectRoot == null || projectRoot.isEmpty
                ? _buildEmptyState()
                : _FeatureListView(projectRoot: projectRoot),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 48, color: StudioTheme.textMuted),
          const SizedBox(height: 16),
          Text('プロジェクトフォルダを開いてください',
              style: TextStyle(color: StudioTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

/// feature_request.yaml を読み込んで表示
class _FeatureListView extends StatefulWidget {
  final String projectRoot;
  const _FeatureListView({required this.projectRoot});

  @override
  State<_FeatureListView> createState() => _FeatureListViewState();
}

class _FeatureListViewState extends State<_FeatureListView> {
  Map<String, dynamic>? _features;
  Map<String, dynamic>? _project;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadYaml();
  }

  @override
  void didUpdateWidget(covariant _FeatureListView old) {
    super.didUpdateWidget(old);
    if (old.projectRoot != widget.projectRoot) _loadYaml();
  }

  void _loadYaml() {
    try {
      final path = '${widget.projectRoot}/AI/specs/feature_request.yaml';
      final file = File(path);
      if (!file.existsSync()) {
        setState(() => _error = 'feature_request.yaml が見つかりません\n$path');
        return;
      }
      final content = file.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap;
      final features = <String, dynamic>{};
      final featuresYaml = yaml['features'] as YamlMap?;
      if (featuresYaml != null) {
        for (final entry in featuresYaml.entries) {
          features[entry.key as String] = {
            'permission': (entry.value as YamlMap)['permission'] ?? '',
            'entity': (entry.value as YamlMap)['entity'] ?? '',
            'description': (entry.value as YamlMap)['description'] ?? '',
          };
        }
      }
      final projectYaml = yaml['project'] as YamlMap?;
      final project = <String, dynamic>{
        'name': projectYaml?['name'] ?? '',
        'version': projectYaml?['version'] ?? '',
      };
      setState(() {
        _features = features;
        _project = project;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'パースエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: StudioTheme.accentRed),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: StudioTheme.accentRed, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadYaml,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_features == null) {
      return const Center(child: CircularProgressIndicator(color: StudioTheme.accentCyan));
    }

    return Column(
      children: [
        // ── プロジェクト情報バー ──
        if (_project != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: StudioTheme.darkBg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: StudioTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_project!['name'],
                      style: const TextStyle(color: StudioTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StudioTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('v${_project!['version']}',
                      style: const TextStyle(color: StudioTheme.accentPurple, fontSize: 11)),
                ),
                const Spacer(),
                Text('${_features!.length} features',
                    style: TextStyle(color: StudioTheme.textMuted, fontSize: 12)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadYaml,
                  icon: const Icon(Icons.refresh, size: 16),
                  color: StudioTheme.textMuted,
                  iconSize: 16,
                  tooltip: '再読み込み',
                ),
              ],
            ),
          ),
        // ── フィーチャーカード一覧 ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _features!.length,
            itemBuilder: (context, index) {
              final name = _features!.keys.elementAt(index);
              final data = _features![name] as Map<String, dynamic>;
              return _FeatureCard(
                name: name,
                permission: data['permission'] as String,
                entity: data['entity'] as String,
                description: data['description'] as String,
                index: index,
                projectRoot: widget.projectRoot,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// FeatureCard
// ─────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String name;
  final String permission;
  final String entity;
  final String description;
  final int index;
  final String projectRoot;

  const _FeatureCard({
    required this.name,
    required this.permission,
    required this.entity,
    required this.description,
    required this.index,
    required this.projectRoot,
  });

  static const _colors = [
    StudioTheme.accentCyan,
    StudioTheme.accentPurple,
    StudioTheme.accentGreen,
    StudioTheme.accentYellow,
    StudioTheme.accentRed,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    final featurePath = '$projectRoot/lib/features/$name';
    final scanResult = _scanFeatureDir(featurePath);

    return GestureDetector(
      onTap: () => _showDetail(context, color, scanResult),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: StudioTheme.sidebarBg,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.extension, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(name,
                      style: const TextStyle(
                          color: StudioTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text('${scanResult.dartFiles.length} dart',
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(permission,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: StudioTheme.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(color: StudioTheme.textSecondary, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Color color, _ScanResult scan) {
    showDialog(
      context: context,
      builder: (_) => _FeatureDetailDialog(
        name: name,
        permission: permission,
        color: color,
        scan: scan,
        projectRoot: projectRoot,
      ),
    );
  }

  _ScanResult _scanFeatureDir(String featurePath) {
    final dir = Directory(featurePath);
    if (!dir.existsSync()) {
      return const _ScanResult(dartFiles: [], allFiles: [], dirStructure: {}, totalDirs: 0, exists: false);
    }

    final dartFiles = <_FileInfo>[];
    final allFiles = <_FileInfo>[];
    final dirStructure = <String, List<_FileInfo>>{};
    int totalDirs = 0;
    final normalized = featurePath.replaceAll('\\', '/');

    for (final entity in dir.listSync(recursive: true)) {
      final relPath = entity.path.replaceAll('\\', '/').replaceFirst('$normalized/', '');

      if (entity is Directory) {
        totalDirs++;
        dirStructure.putIfAbsent(relPath, () => []);
      } else if (entity is File) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        if (fileName == 'GUIDE.md') continue; // GUIDE.md をスキップ

        final dirName = relPath.replaceAll('/$fileName', '');
        final size = entity.lengthSync();
        final info = _FileInfo(name: fileName, relPath: relPath, dirPath: dirName, size: size);

        allFiles.add(info);
        if (fileName.endsWith('.dart')) dartFiles.add(info);
        dirStructure.putIfAbsent(dirName, () => []);
        dirStructure[dirName]!.add(info);
      }
    }

    return _ScanResult(
      dartFiles: dartFiles,
      allFiles: allFiles,
      dirStructure: dirStructure,
      totalDirs: totalDirs,
      exists: true,
    );
  }
}

// ─────────────────────────────────────────────────
// FeatureDetailDialog（utakata diff 統合）
// ─────────────────────────────────────────────────

class _FeatureDetailDialog extends StatefulWidget {
  final String name;
  final String permission;
  final Color color;
  final _ScanResult scan;
  final String projectRoot;

  const _FeatureDetailDialog({
    required this.name,
    required this.permission,
    required this.color,
    required this.scan,
    required this.projectRoot,
  });

  @override
  State<_FeatureDetailDialog> createState() => _FeatureDetailDialogState();
}

class _FeatureDetailDialogState extends State<_FeatureDetailDialog> {
  List<String> _missingDirs = [];
  bool _diffLoading = false;

  static const _layerColors = {
    '1_domain': StudioTheme.accentCyan,
    '2_infrastructure': StudioTheme.accentGreen,
    '3_application': StudioTheme.accentYellow,
    '4_presentation': StudioTheme.accentPurple,
  };

  @override
  void initState() {
    super.initState();
    _runDiff();
  }

  Future<void> _runDiff() async {
    setState(() => _diffLoading = true);
    try {
      final result = await Process.run(
        'dart',
        ['run', 'utakata', 'diff'],
        workingDirectory: widget.projectRoot,
        environment: {'LANG': 'ja_JP.UTF-8'},
      );
      if (!mounted) return;

      final output = result.stdout as String;
      final missing = <String>[];
      bool inMissing = false;
      final featurePrefix = 'features/${widget.name}/';

      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('Missing')) {
          inMissing = true;
        } else if (trimmed.startsWith('Extra')) {
          inMissing = false;
        } else if (inMissing && trimmed.contains(featurePrefix)) {
          final cleaned = trimmed.replaceFirst(featurePrefix, '').trim();
          if (cleaned.isNotEmpty) missing.add(cleaned);
        }
      }

      setState(() {
        _missingDirs = missing;
        _diffLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _diffLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: StudioTheme.editorBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: StudioTheme.borderColor),
      ),
      child: SizedBox(
        width: 750,
        height: 650,
        child: Column(children: [
          // ── ヘッダー ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: StudioTheme.sidebarBg,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: StudioTheme.borderColor)),
            ),
            child: Row(children: [
              Icon(Icons.extension, size: 20, color: widget.color),
              const SizedBox(width: 8),
              Text(widget.name,
                  style: TextStyle(color: widget.color, fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(widget.permission,
                    style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 18),
                color: StudioTheme.textMuted,
              ),
            ]),
          ),
          // ── サマリー ──
          Container(
            padding: const EdgeInsets.all(12),
            color: StudioTheme.darkBg,
            child: Row(children: [
              _StatChip(label: 'Dart', value: '${widget.scan.dartFiles.length}', color: StudioTheme.accentCyan),
              const SizedBox(width: 6),
              _StatChip(label: 'ファイル', value: '${widget.scan.allFiles.length}', color: StudioTheme.accentGreen),
              const SizedBox(width: 6),
              _StatChip(label: 'ディレクトリ', value: '${widget.scan.totalDirs}', color: StudioTheme.accentYellow),
              const Spacer(),
              if (_diffLoading)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: StudioTheme.accentCyan))
              else if (_missingDirs.isNotEmpty)
                _StatChip(label: 'Missing', value: '${_missingDirs.length}', color: StudioTheme.accentRed),
              if (!widget.scan.exists)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: StudioTheme.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('未作成',
                      style: TextStyle(color: StudioTheme.accentRed, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          // ── ファイルツリー + Diff ──
          Expanded(
            child: !widget.scan.exists
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.folder_off, size: 48, color: StudioTheme.accentRed),
                      const SizedBox(height: 16),
                      Text('lib/features/${widget.name}/ が存在しません',
                          style: const TextStyle(color: StudioTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('utakata feature add ${widget.name} で作成してください',
                          style: TextStyle(
                              color: StudioTheme.accentCyan.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontFamily: 'monospace')),
                    ]),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_missingDirs.isNotEmpty) ...[
                        const _SectionLabel(label: 'MISSING (計画にあるが未実装)', color: StudioTheme.accentRed, icon: Icons.warning_amber),
                        for (final dir in _missingDirs) _MissingDirRow(dir: dir),
                        const SizedBox(height: 12),
                      ],
                      const _SectionLabel(label: '実装済みファイル', color: StudioTheme.accentGreen, icon: Icons.check_circle_outline),
                      ..._buildFileTree(),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildFileTree() {
    final widgets = <Widget>[];
    final sortedDirs = widget.scan.dirStructure.keys.toList()..sort();

    for (final dirPath in sortedDirs) {
      final files = widget.scan.dirStructure[dirPath]!;
      if (files.isEmpty) continue; // 空親ディレクトリをスキップ

      final layerKey = dirPath.split('/').first;
      final layerColor = _layerColors[layerKey] ?? widget.color;

      widgets.add(Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: layerColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: layerColor.withValues(alpha: 0.4), width: 2)),
        ),
        child: Row(children: [
          Icon(Icons.folder_outlined, size: 14, color: layerColor.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(dirPath,
                style: TextStyle(color: layerColor, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          ),
          Text('${files.length}',
              style: TextStyle(color: layerColor.withValues(alpha: 0.5), fontSize: 10)),
        ]),
      ));

      for (final file in files) {
        final isDart = file.name.endsWith('.dart');
        final isGenerated = file.name.endsWith('.freezed.dart') || file.name.endsWith('.g.dart');
        final fileColor = isGenerated ? StudioTheme.textMuted : isDart ? StudioTheme.textPrimary : StudioTheme.textMuted;

        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 20, top: 1, bottom: 1),
          child: Row(children: [
            Icon(isDart ? Icons.code : Icons.description, size: 12, color: fileColor.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(file.name,
                  style: TextStyle(
                    color: fileColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontStyle: isGenerated ? FontStyle.italic : FontStyle.normal,
                  )),
            ),
            Text(_formatSize(file.size), style: TextStyle(color: StudioTheme.textMuted, fontSize: 9)),
          ]),
        ));
      }
    }
    return widgets;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────
// 共通ウィジェット & データクラス
// ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SectionLabel({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ]),
    );
  }
}

class _MissingDirRow extends StatelessWidget {
  final String dir;
  const _MissingDirRow({required this.dir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
      child: Row(children: [
        Icon(Icons.folder_off_outlined, size: 12, color: StudioTheme.accentRed.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(dir,
            style: TextStyle(color: StudioTheme.accentRed.withValues(alpha: 0.8), fontSize: 11, fontFamily: 'monospace')),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10)),
      ]),
    );
  }
}

class _FileInfo {
  final String name;
  final String relPath;
  final String dirPath;
  final int size;
  const _FileInfo({required this.name, required this.relPath, required this.dirPath, required this.size});
}

class _ScanResult {
  final List<_FileInfo> dartFiles;
  final List<_FileInfo> allFiles;
  final Map<String, List<_FileInfo>> dirStructure;
  final int totalDirs;
  final bool exists;
  const _ScanResult({required this.dartFiles, required this.allFiles, required this.dirStructure, required this.totalDirs, required this.exists});
}
