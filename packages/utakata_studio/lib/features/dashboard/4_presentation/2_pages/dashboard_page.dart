import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/cli_bridge/cli_bridge_provider.dart';
import '../../../../core/cli_bridge/cli_result.dart';
import '../../../../core/theme/studio_theme.dart';

/// Dashboard 画面: utakata status の結果をビジュアル表示
class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const Icon(Icons.dashboard, size: 16, color: StudioTheme.accentYellow),
              const SizedBox(width: 8),
              Text('DASHBOARD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: StudioTheme.accentYellow,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: _DashboardContent(
              onRefresh: () async {
                final bridge = ref.read(cliBridgeProvider);
                return bridge.run(['status']);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final Future<CliResult> Function() onRefresh;
  const _DashboardContent({required this.onRefresh});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  bool _loading = false;
  CliResult? _result;
  List<_StatusSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final result = await widget.onRefresh();
      setState(() {
        _result = result;
        _sections = _parseStatusOutput(result.stdout);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = null;
        _sections = [];
        _loading = false;
      });
    }
  }

  List<_StatusSection> _parseStatusOutput(String output) {
    final sections = <_StatusSection>[];
    String? currentTitle;
    final currentLines = <String>[];

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // セクションヘッダー検出
      if (trimmed.startsWith('---') && trimmed.endsWith('---')) {
        if (currentTitle != null) {
          sections.add(_StatusSection(currentTitle, List.from(currentLines)));
          currentLines.clear();
        }
        currentTitle = trimmed.replaceAll(RegExp(r'-+\s*'), '').trim();
      } else if (currentTitle != null) {
        currentLines.add(trimmed);
      } else if (trimmed.contains('utakata status')) {
        // タイトル行はスキップ
      } else {
        currentLines.add(trimmed);
      }
    }

    if (currentTitle != null && currentLines.isNotEmpty) {
      sections.add(_StatusSection(currentTitle, currentLines));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: StudioTheme.accentCyan),
            SizedBox(height: 16),
            Text('utakata status を実行中...',
                style: TextStyle(color: StudioTheme.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── ステータスバー ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: StudioTheme.darkBg,
          child: Row(
            children: [
              if (_result != null) ...[
                Icon(
                  _result!.isSuccess ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _result!.isSuccess ? StudioTheme.accentGreen : StudioTheme.accentRed,
                ),
                const SizedBox(width: 8),
                Text(
                  _result!.isSuccess ? 'ステータス取得成功' : 'エラー (exit: ${_result!.exitCode})',
                  style: TextStyle(
                    color: _result!.isSuccess ? StudioTheme.accentGreen : StudioTheme.accentRed,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text('(${_result!.duration.inMilliseconds}ms)',
                    style: TextStyle(color: StudioTheme.textMuted, fontSize: 11)),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('更新', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: StudioTheme.accentCyan),
              ),
            ],
          ),
        ),
        // ── セクション一覧 ──
        Expanded(
          child: _sections.isEmpty
              ? Center(
                  child: Text('データがありません',
                      style: TextStyle(color: StudioTheme.textMuted, fontSize: 13)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    return _StatusSectionCard(
                      section: section,
                      index: index,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatusSection {
  final String title;
  final List<String> lines;
  const _StatusSection(this.title, this.lines);
}

/// セクションカード
class _StatusSectionCard extends StatelessWidget {
  final _StatusSection section;
  final int index;

  const _StatusSectionCard({required this.section, required this.index});

  IconData _iconForTitle(String title) {
    if (title.contains('Flutter')) return Icons.flutter_dash;
    if (title.contains('Lint')) return Icons.rule;
    if (title.contains('Diff') || title.contains('Architecture')) return Icons.compare;
    return Icons.info_outline;
  }

  Color _colorForTitle(String title) {
    if (title.contains('Flutter')) return StudioTheme.accentCyan;
    if (title.contains('Lint')) return StudioTheme.accentGreen;
    if (title.contains('Diff') || title.contains('Architecture')) return StudioTheme.accentYellow;
    return StudioTheme.accentPurple;
  }

  Color _statusColor(String title, List<String> lines) {
    final text = lines.join(' ');
    if (text.contains('✅') || text.contains('No issues')) return StudioTheme.accentGreen;
    if (text.contains('⚠️') || text.contains('Missing')) return StudioTheme.accentYellow;
    if (text.contains('❌') || text.contains('error')) return StudioTheme.accentRed;
    return StudioTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForTitle(section.title);
    final color = _colorForTitle(section.title);
    final statusColor = _statusColor(section.title, section.lines);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: StudioTheme.sidebarBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── セクションヘッダー ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: StudioTheme.borderColor.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(section.title,
                    style: TextStyle(
                        color: StudioTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // ── セクション内容 ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in section.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line,
                        style: TextStyle(
                          color: line.contains('✅')
                              ? StudioTheme.accentGreen
                              : line.contains('⚠️')
                                  ? StudioTheme.accentYellow
                                  : StudioTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          height: 1.5,
                        )),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
