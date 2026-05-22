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
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 個別フィーチャーカード
class _FeatureCard extends StatelessWidget {
  final String name;
  final String permission;
  final String entity;
  final String description;
  final int index;

  const _FeatureCard({
    required this.name,
    required this.permission,
    required this.entity,
    required this.description,
    required this.index,
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

    return Container(
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
                  style: TextStyle(
                      color: StudioTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(permission,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(color: StudioTheme.textSecondary, fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.data_object, size: 14, color: StudioTheme.textMuted),
              const SizedBox(width: 4),
              Text('entity: $entity',
                  style: TextStyle(color: StudioTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}
